import os
import re

## Client Source Code Dir
CLIENT_SRC_DIR = 'E:\Gits\Clients\lyzz\src\game'

def SaveSet(oneset, filename):
    '''save set data into file'''
    if len(oneset) > 0:
        with open(filename, 'w') as f:
            lines = [line+'\n' for line in list(oneset)]
            f.writelines(lines)


def SearchOneServerMsgSet(filepath):
    '''search server's messages from a file and push them into a set'''
    one_set = set()
    with open(filepath, 'r') as f:
        for line in f.readlines():
            if line.find('UserCmd') > 0 and line[:7] == 'message' > 0:
                msg = line[8:].strip()
                one_set.add(msg)
    return one_set

def SearchAllServerMsgSet():
    '''search server's message from all server's proto files and push them into a set'''
    all_set = set()
    for root, dirs, files in os.walk('./'):
        for file in files:
            if file.endswith('.proto'):
                filepath = os.path.join(root, file)
                one_set = SearchOneServerMsgSet(filepath)
                all_set = all_set.union(one_set)
    SaveSet(all_set, 'ServerMsg.txt')
    return all_set

def SearchOneClientMsgSet(filepath):
    '''search client's messages from a file, and then push them into a set'''
    one_set = set()
    with open(filepath, 'r') as f:
        for line in f.readlines():
            if line.find('UserCmd') > 0:
                msg = line
                l = re.findall(r'\w+', msg)
                if len(l) > 0:
                    for word in l:
                        if word.find('UserCmd') > 0:
                            one_set.add(word)
    return one_set

def SerachAllClientMsgSet():
    '''search client's message from all client's lua script files and push them into a set'''
    all_set = set()
    for root, dirs, files in os.walk(CLIENT_SRC_DIR):
        for file in files:
            if file.endswith('.lua'):
                filepath = os.path.join(root, file)
                one_set = SearchOneClientMsgSet(filepath)
                all_set = all_set.union(one_set)
    SaveSet(all_set, 'ClientMsg.txt')
    return all_set

def Search():
    '''search all server's and client's messages, and see differences between them'''
    all_server_set = SearchAllServerMsgSet()
    all_client_set = SerachAllClientMsgSet()
    all_difference_set = all_server_set - all_client_set
    SaveSet(all_difference_set, 'DifferenceMsg.txt')

if __name__ == "__main__":
    Search()