#only merge two state for reorder model_18.txt file.
#python merge_state_mean.py model_18.txt 7,17,12,18,15,16 model_18to15.txt
import re
import sys
import numpy as np

FileI = sys.argv[1]
stateLst = sys.argv[2]
FileO = sys.argv[3]
modelNum = int(re.split('_|.txt',FileI)[1])
stateLst = stateLst.split(',')
out_type_file=open(FileO,'w')

def AVE2state(dictD, s1, s2):
    newDictD={}
    newDictD_f={}
    for k,v in dictD.items():
        if int(k)==s1:
            v1=float(v)
        elif int(k)==s2:
            v2=float(v)
        else:
            newDictD[int(k)]=float(v)
    newDictD[int(s1)]=(float(v1)+float(v2))/2
    for i in sorted(newDictD):
        newDictD_f[i] = newDictD[i]
    return newDictD_f



def Add2dict(adict, key_a, key_b, val): 
    if key_a in adict:
        adict[key_a].update({key_b: val})
    else:
        adict.update({key_a:{key_b: val}})


Dict_pro={}
Dict_tran={}
Dict_emi_0={}
Dict_emi_1={}

with open (FileI,'r') as f:
    for line in f.readlines():
        line = line.strip().split('\t')
        #print(len(line))
        if len(line)==5:
            head = line[1:]
            head.insert(0,'15')
        if len(line)==3:
            Dict_pro[int(line[1])] = float(line[2])
        if len(line)==4:
            #Dict_tran[line[2]][line[1]] = line[3]
            Add2dict(Dict_tran, int(line[1]), int(line[2]), float(line[3]))
        if len(line)==6:
            histone=line[3]
            if int(line[4])  == 0:
                #Dict_emi_0[histone][line[1]] = line[5]
                Add2dict(Dict_emi_0, histone, int(line[1]), float(line[5]))
            if int(line[4])  == 1:
                #Dict_emi_1[histone][line[1]] = line[5]
                Add2dict(Dict_emi_1, histone, int(line[1]), float(line[5]))
                
##------------------------------------------------------1 合并probinit的
##7,17-->11,12; 12,18-->15,18; 15,16-->1,13
merge3_pro = Dict_pro
for j in range(0,len(stateLst),2):
    merge3_pro = sum2state(merge3_pro,int(stateLst[j]),int(stateLst[j+1]))

#merge1_pro = AVE2state(Dict_pro,int(7),int(17))
#merge2_pro = AVE2state(merge1_pro,int(12),int(18))
#merge3_pro = AVE2state(merge2_pro,int(15),int(16))

##------------------------------------------------------2 合并transitionprobs
merge_tran_1={}
for i in range(1,modelNum+1):
    merge3_tran = Dict_tran[i]
    for j in range(0,len(stateLst),2):
        merge3_tran = sum2state(merge3_tran, int(stateLst[j]), int(stateLst[j+1]))
    #merge1_tran = AVE2state(Dict_tran[i], int(7), int(17))
    #merge2_tran = AVE2state(merge1_tran, int(12), int(18))
    #merge3_tran = AVE2state(merge2_tran, int(15), int(16))
    for k,v in merge3_tran.items():
        Add2dict(merge_tran_1, i, k, v) 
##对合并transitionprobs的第二列再次合并
merge_tran_2={}
merge_tran_2_f={}
mergeL = []
for i in stateLst:
    mergeL.append(int(i))
#mergeL = [7,17,12,18,15,16]
for k,v in merge_tran_1.items():
    if k not in mergeL:
        for k1,v1 in v.items():
            Add2dict(merge_tran_2, k, k1, v1)

for k,v in merge_tran_1[mergeL[0]].items():
    for j in range(0,len(stateLst),2):
        m1 = (float(merge_tran_1[int(stateLst[j])][k]) + float(merge_tran_1[int(stateLst[j+1])][k]))/2
        Add2dict(merge_tran_2, int(stateLst[j]), k, m1)
    #m1 = (float(merge_tran_1[7][k]) + float(merge_tran_1[17][k]))/2
    #m2 = (float(merge_tran_1[12][k]) + float(merge_tran_1[18][k]))/2
    #m3 = (float(merge_tran_1[15][k]) + float(merge_tran_1[16][k]))/2
    #Add2dict(merge_tran_2, 7, k, m1)
    #Add2dict(merge_tran_2, 12, k, m2)
    #Add2dict(merge_tran_2, 15, k, m3)

for i in sorted(merge_tran_2):
    for k,v in merge_tran_2[i].items():
        Add2dict(merge_tran_2_f, i, k, v)

##-------------------------------------------------------3 合并emissionprobs
merge_emi_0={}
merge_emi_1={}
histoneLst = ['H3K27ac','H3K27me3','H3K36me3','H3K4me1','H3K4me3','H3K9me3','H4K20me3']
for i in histoneLst:
    merge3_emi = Dict_emi_0[i]
    for j in range(0,len(stateLst),2):
        merge3_emi = AVE2state(merge3_emi, int(stateLst[j]), int(stateLst[j+1]))
    #merge1_emi = AVE2state(Dict_emi_0[i], int(7), int(17))
    #merge2_emi = AVE2state(merge1_emi, int(12), int(18))
    #merge3_emi = AVE2state(merge2_emi, int(15), int(16))
    for k,v in merge3_emi.items():
        Add2dict(merge_emi_0, i, k, v) 
    
    merge3_emi = Dict_emi_1[i]
    for j in range(0,len(stateLst),2):
        merge3_emi = AVE2state(merge3_emi, int(stateLst[j]), int(stateLst[j+1]))
    #merge1_emi = AVE2state(Dict_emi_1[i], int(7), int(17))
    #merge2_emi = AVE2state(merge1_emi, int(12), int(18))
    #merge3_emi = AVE2state(merge2_emi, int(15), int(16))
    for k,v in merge3_emi.items():
        Add2dict(merge_emi_1, i, k, v)

###########################################################print result
print(str(head[0])+"\t"+str(head[1])+"\t"+str(head[2])+"\t"+str(head[3])+"\t"+str(head[4]), file=out_type_file)
n=0
for k,v in merge3_pro.items():
    n=n+1
    if n == k:
        print("probinit"+"\t"+str(k)+"\t"+str(v), file=out_type_file)
    else:
        print("probinit"+"\t"+str(n)+"\t"+str(v), file=out_type_file)    

n=0
for k,v in merge_tran_2_f.items():
    n = n + 1
    if n == k:
        m=0
        for k1,v1 in v.items():
            m=m+1
            if m == k1:
                print("transitionprobs" +"\t"+ str(k) +"\t"+ str(k1) +"\t"+ str(v1), file=out_type_file)
            else:
                print("transitionprobs" +"\t"+ str(k) +"\t"+ str(m) +"\t"+ str(v1), file=out_type_file)
    else:
        l=0
        for k1,v1 in v.items():
            l=l+1
            if l == k1:
                print("transitionprobs" +"\t"+ str(n) +"\t"+ str(k1) +"\t"+ str(v1), file=out_type_file)
            else:
                print("transitionprobs" +"\t"+ str(n) +"\t"+ str(l) +"\t"+ str(v1), file=out_type_file)

m=0
for k,v in merge_emi_0[histoneLst[0]].items():
#    n=0
    m=m+1
    for i in histoneLst:
        if m==k:
            print("emissionprobs" +"\t"+ str(k) +"\t"+ str(n) +"\t"+ i +"\t"+ str(0) +"\t"+ str(merge_emi_0[i][k]), file=out_type_file)
            print("emissionprobs" +"\t"+ str(k) +"\t"+ str(n) +"\t"+ i +"\t"+ str(1) +"\t"+ str(merge_emi_1[i][k]), file=out_type_file)
        else:
            print("emissionprobs" +"\t"+ str(m) +"\t"+ str(n) +"\t"+ i +"\t"+ str(0) +"\t"+ str(merge_emi_0[i][k]), file=out_type_file)
            print("emissionprobs" +"\t"+ str(m) +"\t"+ str(n) +"\t"+ i +"\t"+ str(1) +"\t"+ str(merge_emi_1[i][k]), file=out_type_file)
        n = n + 1
