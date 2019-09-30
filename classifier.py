# -*- coding: utf-8 -*-
"""
Created on Mon Jun 26 16:21:29 2017

@author: Natacha Chenevoy

Python 3

Run the pre-built classifier on two csv files 
(Lancashire_geotag_tweets.csv and Lancashire_towns_tweets.csv)
"""


import pandas as pd
import re
import string
import pickle
import numpy as np
import nltk
nltk.download("stopwords")
from nltk.corpus import stopwords
from nltk import ngrams
#import os

# prevent SettingWithCopyWarning messages from pandas
pd.options.mode.chained_assignment = None

# user to select working folder (containing all files)
#directory_name = os.path.dirname(__file__)

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
	
# open the classifier
print("Fetching classifier")
try:
	f = open('classifier.pickle', 'rb')
	classifier1 = pickle.load(f)
	f.close()
	print("done")
except FileNotFoundError:
	print(bcolors.FAIL + "Error: cannot retrieve file 'classifier.pickle'. Please make sure this file is in the same folder as this python script." + bcolors.ENDC )
	
# Open file containing list of important features for the classifier
print("Fetching word features")
try:
	f = open('word_features.pickle', 'rb')
	word_features = pickle.load(f)
	f.close()
	print("done")
except FileNotFoundError:
	print(bcolors.FAIL + "Error: cannot retrieve file 'word_features.pickle'. Please make sure this file is in the same folder as this python script." + bcolors.ENDC)
	

# get list of english stopwords
stops = set(stopwords.words('english'))

#remove some words from the list that are relevant to hate
item_to_delete = ['you', 'out', 'off', 'them', 'themselves', 'yourself', 'from', 'same']
stopWords = [e for e in stops if e not in item_to_delete]

# add some words to the list as they are frequently found in tweets
item_to_add = ["youre", "you're", "us", "doesnt", "im", "hes", "u", "ya", "ww", "dont", "https", "aint", "theres", "shouldnt", "amp", "wudnt", "gonna", "ur", "cant"]
for e in item_to_add:
    stopWords.append(e)



### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
## ### ###  ###     PRE-PROCESSING      ### ### ### ### ### ### 
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 


def processTweet(tweet):
    """ This takes a tweet (string) and performs a series of scarpping steps on it.
    Returns the edited tweet (string)"""
    
    #Convert to lower case
    tweet = tweet.lower()
    #Convert www.* or https?://* to ''
    tweet = re.sub('((www\.[^\s]+)|(https?://[^\s]+))','',tweet)
    # removing the RT before the @user 
    tweet = re.sub('rt','',tweet) 
    #Replace #word with word
    tweet = re.sub(r'#([^\s]+)', r'\1', tweet)
    #Convert @username to ''
    tweet = re.sub('@[^\s]+','',tweet) 
    #Remove additional white spaces
    tweet = re.sub('[\s]+', ' ', tweet)
    # remove non ASCII characters (emojies)
    tweet= re.sub(r'[^\x00-\x7F]+','', tweet)
    # remove punctuation 
    tweet = "".join(l for l in tweet if l not in string.punctuation)
    #trim
    tweet = tweet.strip('\'"')
    # remove beginning and end space
    tweet = tweet.strip()

    
    return tweet


#
#def replaceThreeOrMore(s):
#    # pattern to look for three or more repetitions of any character
#    pattern = re.compile(r"(.)\1{2,}", re.DOTALL) 
#    return pattern.sub(r"\1\1", s)



### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
## ###       FEATURE EXTRACTION (TOKENISATION)      ### ### ### 
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 

def extract_features(tweet):
    """ This takes a tweet (string) in input.
    First, it runs the pre-processing function to scrape the tweet.
    It then extracts the tweets' features (unigrams, bigrams or trigrams) 
    Finally, it looks at which important classifier features (if any) 
        are present in the tweet
    It returns a dictionnary indicating whether each important classifier feature 
        is present or not in the tweet"""
        
    # run pre-processing function to clean the tweet
    tweet = processTweet(tweet)
    
    features = []
    
    #split tweet into words
    all_words = tweet.split()
    
    for w in all_words:
        #check if the word starts with a letter
        val = re.search(r"^[a-zA-Z][a-zA-Z0-9]*$", w)
        #ignore if it is a stop word
        if (w in stopWords or val is None):
            continue
        else:
            features.append(w.lower())
            
       
    # get bigrams
    bigrams = list(ngrams(features, 2))
    features.extend(bigrams)
        
    # get trigrams 
    trigrams = list(ngrams(features, 3))
    features.extend(trigrams)
        
    # create a dictionnary where the key is an important feature of our classifier
    # (these features were imported in the pickle file)
    # and the values indicates whether the feature is present in the tweet (True or False)   
    features_dico = {}
    for word in word_features:
        features_dico['contains({})'.format(word)] = (word in features)
    
    return features_dico




### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
## ###        CLASSIFICATION OF GEOTAGGED TWEETS        ### ### 
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
print("Initialising classification of geottagged tweets...")

try:
	data_to_classify = pd.read_csv('Lancashire_geotag_tweets.csv', encoding='ISO-8859-1')

	# replace '' by NA and then delete the row
	data_to_classify['text'].replace('', np.nan, inplace=True)
	data_to_classify.dropna(subset=['text'], inplace=True)

	# Add a new column with the result of the classification (0: non hateful, 1: hateful)   
	data_to_classify["label"] = data_to_classify["text"].apply(lambda x: classifier1.classify(extract_features(x)))

	# Add a new column with the probability of the classificaiton being correct
	data_to_classify["proba"] =  data_to_classify["text"].apply(lambda x: classifier1.prob_classify(extract_features(x)).prob(1))

	# If the proba of correct classification for a tweet classified as 'hateful' 
	# is less than 0.72 (arbitrary), change it to non hateful
	data_to_classify["label"][(data_to_classify['label'] == 1) & ((data_to_classify['label'] == 1) & (data_to_classify['proba'] < 0.72))] = 0
	 

	data_to_classify.to_csv("classified_Lancashire_geotag_tweets.csv")
	
	print("done")
	
	

except FileNotFoundError:
	print(bcolors.FAIL + "Error: cannot retrieve the file: 'Lancashire_geotag_tweets.csv'. Please make sure this file is in the same folder as this python script." + bcolors.ENDC)



### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
## ###     CLASSIFICATION OF TWEETS WITH HOME TOWN LOCATION     ### ### 
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###  

print("Initialising classification of tweets with home town location...")

try:
	data_to_classify = pd.read_csv('Lancashire_towns_tweets.csv', encoding='ISO-8859-1')

	# replace '' by NA and then delete the row
	data_to_classify['text'].replace('', np.nan, inplace=True)
	data_to_classify.dropna(subset=['text'], inplace=True)

	# Add a new column with the result of the classification (0: non hateful, 1: hateful)   
	data_to_classify["label"] = data_to_classify["text"].apply(lambda x: classifier1.classify(extract_features(x)))

	# Add a new column with the probability of the classificaiton being correct
	data_to_classify["proba"] =  data_to_classify["text"].apply(lambda x: classifier1.prob_classify(extract_features(x)).prob(1))

	# If the proba of correct classification for a tweet classified as 'hateful' 
	# is less than 0.72 (arbitrary), change it to non hateful
	data_to_classify["label"][(data_to_classify['label'] == 1) & ((data_to_classify['label'] == 1) & (data_to_classify['proba'] < 0.72))] = 0

					
	data_to_classify.to_csv("classified_Lancashire_town_tweets.csv")
	
	print("done")
	
	### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
	## ###       COUNT TWEETS FOR EACH TOWNS OF LANCASHIRE          ### ### 
	### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

	print("Initialising count of tweets per towns in Lancashire...")

	try:
		towns = pd.read_csv('Towns_List.csv', sep = ";")

		# Initialise dataframe for counts of tweets per town
		df_out = pd.DataFrame() 

		# for all towns in Lancashire
		for town in towns["Town"][towns["County"] == "Lancashire"]:
			
			#town = "Lancaster"
			# select tweets (with home town location) in this town
			subset = data_to_classify[data_to_classify["town"] == town]

			d = {'Total' : len(subset), 'True' : (subset["label"] == 1).sum(), 'False' : (subset["label"] == 0).sum(), 'town' : town}
			series = pd.Series(d)
			df_out = df_out.append(series, ignore_index = True) # add this series to the final dataframe
			
			# count the number of hateful tweets 
			df_out["True"].sum()
			
		# Define column town as index
		df_out = df_out.set_index(["town"])

		df_out.to_csv("Lancashire_towns_count.csv")

		print("done")

	except FileNotFoundError:
		print(bcolors.FAIL +"Error: cannot retrieve the file: 'Towns_List.csv'. Please make sure this file is in the same folder as this python script." + bcolors.ENDC)

	
except FileNotFoundError:
	print(bcolors.FAIL + "Error: cannot retrieve the file: 'Lancashire_towns_tweets.csv'. Please make sure this file is in the same folder as this python script." + bcolors.ENDC)






#%% 


