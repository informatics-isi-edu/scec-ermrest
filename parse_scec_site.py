import urllib2
import sys
import re
from bs4 import BeautifulSoup

import csv
import collections


studies = ["BBP_June2013_Study","BBP_May2013_Study"]

simTags= ["Broadband Version","Velocity model version","Validation package version","Simulation Start Time","Simulation End Time","Simulation ID"]


hrefTags= ["Sim Spec","RotD50 Bias Plot","RotD50 Map GOF Plot","Respect Bias Plot","GMPE Comparison Bias Plot",
           "RotD50 Dist Bias Linear","RotD50 Dist Bias Log","Station Map","Rupture file"]



def rootify(leafRoot,val):
    return leafRoot+re.sub('./','/',val)


def initCSVWriter(fileName,headers):
    with open(fileName,'w') as simfile:
        fbwriter = csv.DictWriter(simfile,fieldnames=headers)
        fbwriter.writer.writerow(fbwriter.fieldnames)
        return fbwriter


def parseTdTag(tdTagName,fTags,simDict):
    for i in range(len(fTags)):
        if fTags[i].string == tdTagName:
            ffb=re.sub(' ','_',tdTagName)
            simDict[ffb]=fTags[i+1].string.strip()


def parseHrefTag(tdTagName,fTags,simDict,leafRoot):
    for i in range(len(fTags)):
        if fTags[i].string == tdTagName:
            if fTags[i].string == "Station Map":
                ffb=re.sub(' ','_',tdTagName)+"_PNG"
                simDict[ffb]=rootify(leafRoot,fTags[i].find_next('a').get('href').strip())
                ffb=re.sub(' ','_',tdTagName)+"_KML"
                simDict[ffb]=rootify(leafRoot,fTags[i].find_next('a').find_next('a').get('href').strip())
            elif fTags[i].string == "Rupture file":
                ffb=re.sub(' ','_',tdTagName)+"_data"
                simDict[ffb]=rootify(leafRoot,fTags[i].find_next('a').get('href').strip())
                ffb=re.sub(' ','_',tdTagName)+"_PNG"
                simDict[ffb]=rootify(leafRoot,fTags[i].find_next('a').find_next('a').get('href').strip())
            else:
                ffb=re.sub(' ','_',tdTagName)
                simDict[ffb]=rootify(leafRoot,fTags[i].find_next('a').get('href').strip())


def parseStation(fTags,leafRoot,simIndex):
    for i in range(len(fTags)):
        if fTags[i].string != "Simulation Results":
            simDict = collections.OrderedDict()
            simDict['sim_index']=simIndex
            simDict['station_id']=fTags[i].string
            tr1=fTags[i].find_next('tr')
            for j in range(1, 6):
                fab=tr1.find_next('td')
                if j != 5:
                    ffb=re.sub(' ','_',fab.string)+"_data"
                    simDict[ffb]=rootify(leafRoot,fab.find_next("a").get('href'))
                    ffb=re.sub(' ','_',fab.string)+"_PNG"
                    simDict[ffb]=rootify(leafRoot,fab.find_next("a").find_next("a").get('href'))
                else:
                    ffb=re.sub(' ','_',fab.string)+"_PNG"
                    simDict[ffb]=rootify(leafRoot,fab.find_next("a").get('href'))
                tr1=tr1.find_next('tr')
            with open('fbstat.csv','a') as statfile:
                fabwriter = csv.DictWriter(statfile,fieldnames=stats_header)
                fabwriter.writerow(simDict)


def getSoup(url):
    sf = urllib2.urlopen(url)
    shtml = sf.read()
    return BeautifulSoup(shtml)


def parseLeaf(leafRoot,simID,simIndex):
    leafURL = leafRoot+"/index-"+simID+".html"
    leaf_file = urllib2.urlopen(leafURL)
    leaf_html = leaf_file.read()
    leaf_soup = BeautifulSoup(leaf_html)
    tdTags = leaf_soup.findAll('td')
    h2Tags = leaf_soup.findAll('h2')
    simDict = collections.OrderedDict()
    simDict['sim_index']=simIndex
    for fb in simTags:
        parseTdTag(fb,tdTags,simDict)

    for fb in hrefTags:
        parseHrefTag(fb,tdTags,simDict,leafRoot)

    with open('fbsim.csv','a') as simfile:
        fabwriter = csv.DictWriter(simfile,fieldnames=sims_header)
        fabwriter.writerow(simDict)
    parseStation(h2Tags,leafRoot,simIndex)





def main():
    global sims_header
    global stats_header


    sims_header = ['sim_index','Broadband_Version', 'Velocity_model_version', 'Validation_package_version', 
                   'Simulation_Start_Time', 'Simulation_End_Time', 'Simulation_ID', 'Sim_Spec', 'RotD50_Bias_Plot', 
                   'RotD50_Map_GOF_Plot', 'Respect_Bias_Plot', 'GMPE_Comparison_Bias_Plot', 'RotD50_Dist_Bias_Linear', 
                   'RotD50_Dist_Bias_Log', 'Station_Map_PNG','Station_Map_KML', 'Rupture_file_data', 'Rupture_file_PNG']

    stats_header = ['sim_index','station_id', 'Velocity_data', 'Velocity_PNG', 
                    'Acceleration_data', 'Acceleration_PNG', 'RotD50_data', 'RotD50_PNG', 
                    'Respect_data', 'Respect_PNG', 'Overlay_PNG']


    initCSVWriter('fbsim.csv',sims_header)
    initCSVWriter('fbstat.csv',stats_header)

    simIndex=0
    for study in studies:
        u1 = 'http://bbpvault.usc.edu/bbp/'+study+'/gp/'
        print u1
        dirs = getSoup(u1).findAll(alt="[DIR]")
        for dir in dirs:    
            u2 = u1+dir.find_next('a').string+"outdata/"
            print u2
            try:
                sims = getSoup(u2).findAll(alt="[DIR]")
            except urllib2.HTTPError, e:
                print(e.code)
            for sim in sims:
                simID = re.sub('/','',sim.find_next('a').string)
                #simUrl = u2+simID+"/index-"+simID+".html"
                simRoot = u2+simID
                try:
                    simIndex+=1
                    parseLeaf(simRoot,simID,simIndex)
                except urllib2.HTTPError, e:
                    print(e.code)
                            
    
#----------    

main()
