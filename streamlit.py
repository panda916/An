#!/usr/bin/env python
# coding: utf-8

# In[24]:


import streamlit as st
import streamlit.components.v1 as stc
import pandas as pd
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
import time

from selenium.webdriver.chrome.service import Service as ChromeService
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
chrome_options = webdriver.ChromeOptions()
#chrome_options.add_argument('--headless')
chrome_options.add_argument('--no-sandbox')
chrome_options.add_argument('--disable-dev-shm-usage')

from selenium import webdriver
from selenium.webdriver.chrome.options import Options


chrome_options = Options()
chrome_options.add_argument("--incognito")
chrome_options.add_argument("--window-size=1920x1080")
options = webdriver.ChromeOptions()
options.add_argument('--headless')
options.add_argument('--disable-gpu')
options.add_argument('--log-level=3')

import os, sys
import argparse



# In[25]:


# File Processing Pkgs
import pandas as pd



def main():
    
    st.title("File Upload Tutorial")

    menu = ["Home","Dataset","DocumentFiles","About"]
    choice = st.sidebar.selectbox("Menu",menu)
    st.subheader("Dataset")
    data_file = st.file_uploader("Upload CSV",type=['csv'])
    
    
    if st.button("Process"):
        
        df = pd.read_csv(data_file)
        st.dataframe(df)    
                   
        data = pd.DataFrame(columns=["date", "desc", "exchange rate"])
        st.dataframe(data)
        
       

            
        @st.cache_resource 
        def get_driver():
            webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
            return driver.get('https://leanx.eu/en/sap/table/BSEG')


        get_driver()
        

        st.write(driver.current_url)
            

        driver.quit()
        st.dataframe(data)
        data.to_csv(r"test.csv")


# In[33]:


if __name__ == '__main__':
    main()







