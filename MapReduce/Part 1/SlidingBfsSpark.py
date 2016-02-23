from pyspark import SparkContext
from math import log
import Sliding, argparse, multiprocessing
#multiprocessing and log are for OPTIMIZATION

def bfs_map(value):
    """value is a (key, value) pair where key = a configuration and 
    value = level.  Take this (key, value) pair and 
    generate a list of all possible children for this configuration
    EFFICIENCY IMPROVEMENT: include parent in list to return to be rid
    of need for union"""
    """YOUR CODE HERE"""
    toRtn = list() #our list to return
    parent = (value[0], value[1])
    toRtn.append(parent) #add parent to list
    if (value[1] == level): #we only want to look at values where its level == global level
        for child in Sliding.children(WIDTH, HEIGHT, value[0]): #this looks at each child in the list
            elem = (child, level+1) #create a new (K, V) pair
            toRtn.append(elem)  #append this entry to our return list
    return toRtn #return this set of (K, V) pairs


def bfs_reduce(value1, value2):
    """this function takes two values of a key (which, in this case, are levels);
    need to return the minimum of the two entries, as one is a duplicate of the 
    other"""
    """YOUR CODE HERE"""
    return min(value1, value2) #gets the minimum value, returns one
   
def solve_sliding_puzzle(master, output, height, width):
    """
    Solves a sliding puzzle of the provided height and width.
     master: specifies master url for the spark context
     output: function that accepts string to write to the output file
     height: height of puzzle
     width: width of puzzle
    """
    # Set up the spark context. Use this to create your RDD
    sc = SparkContext(master, "python")

    # Global constants that will be shared across all map and reduce instances.
    # You can also reference these in any helper functions you write.
    global HEIGHT, WIDTH, level, local_level

    # Initialize global constants
    HEIGHT=height
    WIDTH=width
    level = 0 # this "constant" will change, but it remains constant for every MapReduce job
    
    # The solution configuration for this sliding puzzle. You will begin exploring the tree from this node
    sol = Sliding.solution(WIDTH, HEIGHT)


    """ YOUR MAP REDUCE PROCESSING CODE HERE """
    cores = multiprocessing.cpu_count() #OPTIMIZATION, gives cpu count for this machine, for partitionBy
    constant = 8
    lst = sc.parallelize([(sol, level)]).partitionBy(cores) #this creates the initial (K, V) RDD comprised of: (0, ('A', 'B', 'C', '-'))
    
    lst = lst.flatMap(bfs_map).reduceByKey(bfs_reduce)
    level+=1 #this is so that repartition doesn't run right when level = 0
    while (True): #continually loop
        if (level % constant == 0):
            new_lst = lst.flatMap(bfs_map).repartition(cores).reduceByKey(bfs_reduce)
            #new_lst is going to be lst + the new children in lst
            if (new_lst.count() == lst.count()):
                break
        else:
            new_lst = lst.flatMap(bfs_map).reduceByKey(bfs_reduce)
        lst = new_lst #set lst to equal the new list + non-duplicate children
        level+=1 #increment level
    
    """ YOUR OUTPUT CODE HERE """
    
    toPrint = "" #set the empty string
    for pair in lst.collect():
        toPrint += (str(pair[1]) + " " + str(pair[0]) + "\n")
        #get the elements to add to the string
    output(toPrint) #write the string

    sc.stop()



""" DO NOT EDIT PAST THIS LINE

You are welcome to read through the following code, but you
do not need to worry about understanding it.
"""

def main():
    """
    Parses command line arguments and runs the solver appropriately.
    If nothing is passed in, the default values are used.
    """
    parser = argparse.ArgumentParser(
            description="Returns back the entire solution graph.")
    parser.add_argument("-M", "--master", type=str, default="local[8]",
            help="url of the master for this job")
    parser.add_argument("-O", "--output", type=str, default="solution-out",
            help="name of the output file")
    parser.add_argument("-H", "--height", type=int, default=2,
            help="height of the puzzle")
    parser.add_argument("-W", "--width", type=int, default=2,
            help="width of the puzzle")
    args = parser.parse_args()


    # open file for writing and create a writer function
    output_file = open(args.output, "w")
    writer = lambda line: output_file.write(line + "\n")

    # call the puzzle solver
    solve_sliding_puzzle(args.master, writer, args.height, args.width)

    # close the output file
    output_file.close()

# begin execution if we are running this file directly
if __name__ == "__main__":
    main()

