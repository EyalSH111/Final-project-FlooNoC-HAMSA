#! /opt/python/3.5.2/bin/python3.5
#
#                        Copyright (C) 2015-2018 by EnICS Labs
#                01
#              01 10
#             1 10 010101010              1010     0101010    1010101
#             1 10         0              1  0    10     0   0      1
#             1   1010101010              1  0   01  01010  1   10101
#              010                        1  0   0  10      1  0
#            01  01            01010101   1  0  1  01       1  01
#           10 01 1010101010  10       0  1  0  1  0        10  10
#           1  01          0  1   10   0  1  0  1  0         0    1
#           10   01010101010  1  01 1  0  1  0  1  0          10   0
#            01010            1  0  1  0  1  0  1  0           01   1
#            0101             1  0  1  0  1  0  1  01           10  1
#           1    0            1  0  1  0  1  0   0  10           0  1
#          0  10 01010101010  1  0  1  0  1  0   01  01010  10101   1
#          0 0 0           0  1  0  1  0  1  0    10     0  1      01
#          0 01  01010101010  1010  1010  1010     0101010  10101010
#          0    1
#           1010
#                     ------<< System-on-Chip Lab >>-------
#
# This module is confidential and proprietary property of EnICS Labs and the possession or use
# of this file requires a written license from EnICS Labs.
#
#
# Note: This header template is automatically generated with EMACS template defined in:
#    (1) ~$USER/.emacs.d/handy_functions.el
#    (2) ~$USER/.emacs.d/init.el
# ---------------------------------------------------------------------------------------------------------- #
#
# Category    : Script (Python)
# Title       : [FILL ME]
# Project     : common
# Filename    : matrix_address_parsing.py
# Author      : Slava Yuzhaninov (yuzhans@biu.ac.il)
# Created     : Wed Feb 28 21:55:06 2018 (+0200)
# Last-Updated: Tue Jul  7 22:47:32 2020 (+0300)
#           By: Slava Yuzhaninov
#     Update #: 232
#
# Description : [FILL ME]
#
# ---------------------------------------------------------------------------------------------------------- #


import sys
import glob
import os
import pprint   # Nice print of structures
import re       # Regular expressions package
import math
import types    # Type evaluation
import argparse # Parser for command-line options & arguments
import datetime # Used for time-stamp
import xlrd     # Used for excel parsing

import pandas as pd                 # Excel data parsing and filtering
pp = pprint.PrettyPrinter(indent=3) # Used for debugging of objects like pandas or dictionaries

project         = os.environ.get('PROJECT')
username        = os.environ.get('USER') # Used to identify the user that generated the Verilog and IO files.
script_name     = '$PULP_ENV/src/ips/crg_legacy/scripts/common/' + os.path.basename(__file__)

# ------------------------------------------------------------------------------------------------------------ #
# Perforce check-out                                                                                           #
# ------------------------------------------------------------------------------------------------------------ #
def OpenFileForEdit(file, changelist = ""):
   '''
   Open a file for edit, if a change-list is passed in, then open it in that list.
   Sourced from: http://stackoverflow.com/questions/184187/how-do-i-check-out-a-file-from-perforce-in-python
   '''
   cmd = "icmp4 edit "
   if changelist:
      cmd += " -c " + changelist + " "
   ret = os.popen(cmd + file).readline().strip()
   if not ret.endswith("opened for edit"):
      print ("Couldn't open", os.path.basename(file), "for edit: ---> IGNORE this message if it's a local (not ICMP4) file")
      print (ret)
      raise ValueError


# ------------------------------------------------------------------------------------------------------------ #
# Create file handler for product file:                                                                        #
# ------------------------------------------------------------------------------------------------------------ #
def open_file (path, basename, ext):
   f_full_path = path + basename + ext
   try:
      #OpenFileForEdit(f_full_path)
      f = open(f_full_path,'w')
   except ValueError:
      f = open(f_full_path,'w+')
   return f


# ------------------------------------------------------------------------------------------------------------ #
# Input arguments:                                                                                             #
# ------------------------------------------------------------------------------------------------------------ #
parser = argparse.ArgumentParser(
   description=
   '''
   The script parses a the NoC address excel file, and generates address ranges defines for verification & software.
   '''
)

parser.add_argument('-xls', '--excel_file', help='Excel file of the NoC address data to be parsed', required=True)
parser.add_argument('-i', '--indent', type = int, help='Depth of indentation', default=3)
args = parser.parse_args()


# ------------------------------------------------------------------------------------------------------------ #
# Input excel file information:                                                                                #
# ------------------------------------------------------------------------------------------------------------ #
xls_fullpath = os.path.abspath(args.excel_file)
xls_filename = os.path.basename(args.excel_file)
xls_name     = re.sub(r'\.xls[xm]?','',xls_filename)
xls_dir      = xls_fullpath.replace(xls_filename,'')
xls_info_d   = {'name' : xls_name, 'full_path' : xls_fullpath, 'directory' : xls_dir}

source_str   = ' NOTE: This file generated by ' + script_name + 'script applied on ' + xls_filename + ' file'

f_e = open_file (path = xls_dir, basename = project + '_auto_defines', ext = '.e')
f_e_fullpath = xls_dir + project + '_auto_defines' + '.e'

f_c = open_file (path = xls_dir, basename = project + '_auto_defines', ext = '.h')
f_c_fullpath = xls_dir + project + '_auto_defines' + '.h'

f_addr = open_file (path = xls_dir, basename = project + '_address_map', ext = '.txt')
f_addr_fullpath = xls_dir + project + '_address_map' + '.txt'


logo_str        = '''
--                          01
--                        01 10
--                       1 10 010101010              1010     0101010    1010101
--                       1 10         0              1  0    10     0   0      1
--                       1   1010101010              1  0   01  01010  1   10101
--                        010                        1  0   0  10      1  0
--                      01  01            01010101   1  0  1  01       1  01
--                     10 01 1010101010  10       0  1  0  1  0        10  10
--                     1  01          0  1   10   0  1  0  1  0         0    1
--                     10   01010101010  1  01 1  0  1  0  1  0          10   0
--                      01010            1  0  1  0  1  0  1  0           01   1
--                      0101             1  0  1  0  1  0  1  01           10  1
--                     1    0            1  0  1  0  1  0   0  10           0  1
--                    0  10 01010101010  1  0  1  0  1  0   01  01010  10101   1
--                    0 0 0           0  1  0  1  0  1  0    10     0  1      01
--                    0 01  01010101010  1010  1010  1010     0101010  10101010
--                    0    1
--                     1010
--                               ------<< System-on-Chip Lab >>-------
--
--           This module is confidential and proprietary property of EnICS Labs and the possession or use
--                          of this file requires a written license from EnICS Labs.

'''


################################################################################################################
# Write EnICS header to the file:                                                                              #
################################################################################################################
def write_header_to_file (f, logo_str, comm_prefix):

   copyright_str        = "                              Copyright (C) 2015-" + str(datetime.date.today().year) + " by EnICS Labs"
   title_str            = ' Title          : Memories ranges defines'
   project_str          = ' Project        : ' + project
   author_str           = ' Generated by   : ' + username
   gen_with_str         = ' Generated with : ' + script_name
   creation_date_str    = ' Created        : ' + datetime.datetime.now().strftime('%B %d %Y at %H:%M:%S')
   description_str      = ' Description    : Address ranges defines for verification/software'
   separate_line_str    = ' ----------------------------------------------------------------------------------------------------------- '

   f.write(comm_prefix + copyright_str + '\n')
   f.write(logo_str + '\n')
   f.write(comm_prefix + title_str + '\n')
   f.write(comm_prefix + project_str + '\n')
   f.write(comm_prefix + author_str + '\n')
   f.write(comm_prefix + gen_with_str + '\n')
   f.write(comm_prefix + creation_date_str + '\n')
   f.write(comm_prefix + description_str + '\n')
   f.write(comm_prefix + separate_line_str + '\n')
################################################################################################################


def split_str_with_char(string, length=4, char='_', prefix='0x', upper_case=True):
   nibles_lst = [string[0+i:length+i] for i in range(0, len(string), length)]
   return prefix + (char.join(nibles_lst).upper() if upper_case else char.join(nibles_lst))

def lang_chars(arg):
    switcher = {
        'e': {'first_char': '', 'last_char': ';'},
        'c': {'first_char': '#', 'last_char': ''}
    }
    return switcher.get(arg,{'first_char': '', 'last_char': ''})

################################################################################################################
# Write ranges                                                                                             #
################################################################################################################
def write_ranges (xls_fullpath, sheet_name, f, if_type, language):

   df = pd.read_excel(
      xls_fullpath              ,
      sheet_name    = sheet_name
   )

   filter_lst = ['Component', 'M/S', 'I/F Type', 'Access Type',
                 'Access Range Code', 'Base Address [hex]',
                 'Size [hex]', 'Sub-System']

   df = df[df['I/F Type'] == if_type][filter_lst]
   pp.pprint(df)
   df = df[df['Component'].notnull()]
   df = df.where((pd.notnull(df)), None) # Transform NaN values to None
   longest_code = len(max(df['Access Range Code'].tolist(), key=len))

   prefix = lang_chars(language).get('first_char')
   suffix = lang_chars(language).get('last_char')
   split_char = '' if (language == 'c') else '_'

   for i,row in df.iterrows():
      addr_goal       = row['Access Type']
      range_code      = row['Access Range Code']
      range_base      = int('0x' + str(row['Base Address [hex]']),16)
      range_size      = int('0x' + str(row['Size [hex]']),16)
      m_s             = row['M/S']

      align_str  = ' '*(longest_code - len(range_code) + 3)

      max_range = range_base + range_size - 1

      f.write('\n')
      f.write(prefix + 'define MIN_' + range_code + align_str + split_str_with_char(
         string = str(hex(range_base))[2:],
         char   = split_char
      ) + suffix + '\n')
      f.write(prefix + 'define MAX_' + range_code + align_str + split_str_with_char(
         string = str(hex(max_range))[2:],
         char   = split_char
      )  + suffix + '\n')

################################################################################################################

################################################################################################################
# Write APB ranges                                                                                             #
################################################################################################################
def write_apb_ranges (xls_fullpath, sheet_name, f, language):

   df = pd.read_excel(
      xls_fullpath              ,
      sheet_name    = sheet_name
   )

   filter_lst = ['Component', 'M/S', 'I/F Type', 'Access Type',
                 'Access Range Code', 'Base Address [hex]',
                 'Size [hex]', 'Last Valid Addr [hex]', 'Sub-System']

   df = df[df['I/F Type'] == 'APB'][filter_lst]
   df = df[df['Component'].notnull()]
   df = df.where((pd.notnull(df)), None) # Transform NaN values to None
   longest_code = len(max(df['Access Range Code'].tolist(), key=len))

   prefix = lang_chars(language).get('first_char')
   suffix = lang_chars(language).get('last_char')
   split_char = '' if (language == 'c') else '_'

   for i,row in df.iterrows():
      addr_goal       = row['Access Type']
      range_code      = row['Access Range Code']
      range_base      = int('0x' + str(row['Base Address [hex]']),16)
      range_size      = int('0x' + str(row['Size [hex]']),16)
      null_range_base = range_base + int('0x' + str(row['Last Valid Addr [hex]']),16) + 4 if (row['Last Valid Addr [hex]']) else None
      m_s             = row['M/S']

      align_str  = ' '*(longest_code + len('_NULL') - len(range_code) + 3)

      max_range = range_base + range_size - 1

      f.write('\n')
      f.write(prefix + 'define MIN_' + range_code + align_str + split_str_with_char(
         string = str(hex(range_base))[2:],
         char   = split_char
      ) + suffix + '\n')
      f.write(prefix + 'define MAX_' + range_code + align_str + split_str_with_char(
         string = str(hex(max_range))[2:],
         char   = split_char
      )  + suffix + '\n')

      if (null_range_base and max_range > null_range_base):
         small_align_str = ' '*(len(align_str) - len('_NULL'))

         f.write('\n')
         f.write(prefix + 'define MIN_NULL_' + range_code + small_align_str + split_str_with_char(
            string = str(hex(null_range_base))[2:],
            char   = split_char
         ) + suffix + '\n')
         f.write(prefix + 'define MAX_NULL_' + range_code + small_align_str + split_str_with_char(
            string = str(hex(max_range))[2:],
            char   = split_char
         ) + suffix + '\n')


################################################################################################################

################################################################################################################
# Write APB base entries for Ceragon's legacy of automatically generated regfiles                              #
################################################################################################################
def write_apb_slaves_txt (xls_fullpath, sheet_name, f):

   df = pd.read_excel(
      xls_fullpath              ,
      sheet_name    = sheet_name
   )

   filter_lst = ['Component', 'I/F Type', 'Base Address [hex]']

   df = df[df['I/F Type'] == 'APB'][filter_lst]
   df = df[df['Component'].notnull()]
   df = df.where((pd.notnull(df)), None) # Transform NaN values to None

   for i,row in df.iterrows():
      component  = row['Component']
      range_base = str(row['Base Address [hex]']).upper()

      f.write(range_base + ' ' + component + '_apb N/A' + '\n')


################################################################################################################

# Check-out files:
#OpenFileForEdit(f_e_fullpath)
#OpenFileForEdit(f_c_fullpath)
#OpenFileForEdit(f_addr_fullpath)

# ------------------------------------------------------------------------------------------------------------ #
# SPECMAN file fill:                                                                                           #
# ------------------------------------------------------------------------------------------------------------ #
write_header_to_file (f_e, logo_str, '--')

f_e.write('\n<\'\n')
#write_ranges     (xls_fullpath, 'Address space', f_e, 'OCP', 'e')
#write_ranges     (xls_fullpath, 'Address space', f_e, 'AXI', 'e')
write_apb_ranges (xls_fullpath, 'Address space', f_e, 'e')
f_e.write('\n\'>')
f_e.close
# ------------------------------------------------------------------------------------------------------------ #

# ------------------------------------------------------------------------------------------------------------ #
# C file fill:                                                                                                 #
# ------------------------------------------------------------------------------------------------------------ #
write_header_to_file (f_c, re.sub(r'\n--','\n//',logo_str, re.DOTALL | re.MULTILINE), '//')

f_c.write('\n' + '#ifndef AUTO_ADDR_H' + '\n' + '#define AUTO_ADDR_H' + '\n')
#write_ranges     (xls_fullpath, 'Address space', f_c, 'OCP', 'c')
#write_ranges     (xls_fullpath, 'Address space', f_c, 'AXI', 'c')
write_apb_ranges (xls_fullpath, 'Address space', f_c, 'c')
f_c.write('\n' + '#endif // #ifndef AUTO_ADDR_H')
f_c.close
# ------------------------------------------------------------------------------------------------------------ #

# ------------------------------------------------------------------------------------------------------------ #
# This file is used for legacy automated registers. The $SCRIPTS/design/gen_HeaderFile.pl                      #
# Ceragon's legacy script gets it as input argument to generate .h header file                                 #
# ------------------------------------------------------------------------------------------------------------ #
write_apb_slaves_txt(xls_fullpath, 'Address space', f_addr)
f_addr.close
