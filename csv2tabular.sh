#! /bin/bash

# This script requires GNU Awk 4.0 or later.

VERSION_AND_LICENSE="
csv2tabular.sh  1.0.0
Copyright (C) 2019 kitanokitsune

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see http://www.gnu.org/licenses/."


PROGRAM_USAGE="
Usage: ${0##*/} [OPTION]... [-t STRING...]
  This script is a tool to display csv data in a tabular form.
  It reads standard input, formats it and writes standard output.

options:
  -s {0..3}           Border style; '0'= no border, '1'= no header style,
                      '2'= header and body style, '3'= partition every row.
  -r -l -c            Alignment of column; 'r'=right, 'l'=left, 'c'=center.
                      To specify each column at once, a sequence of the
                      options, like '-rrlc', is allowed. If the sequence
                      is shorter than columns, the remains are left-aligned.
  -p INTEGER          Amount of column cell padding; Default is 1.
  -i INTEGER          Amount of indent; Default is 2.
  -t STRING...        Insert header data; All the rest command line after '-t'
                      is assumed as a row of header data, and is inserted in
                      the begining of csv. 
  -v                  Version and license information.
  -h                  This help.
Examples:
        ${0##*/} -s1 -i10 -p0 < file.csv
        cat file.csv | ${0##*/} -rlrc -t 'No.' 'Item' 'Price' 'Status'"


usage_exit() {
    echo -e "${PROGRAM_USAGE}" 1>&2
    exit
}

show_version() {
    echo -e "${VERSION_AND_LICENSE}" 1>&2
    exit
}


set +H

paddingL=1
paddingR=1
indentL=2
TBL_STYLE=2
COLALIGN=()

while getopts lrcs:i:p:tvh OPT
do
    case $OPT in
        l ) COLALIGN=("${COLALIGN[@]}" l)
            ;;
        r ) COLALIGN=("${COLALIGN[@]}" r)
            ;;
        c ) COLALIGN=("${COLALIGN[@]}" c)
            ;;
        s ) if [[ $OPTARG =~ ^[0-3]$ ]]; then
                TBL_STYLE=$OPTARG
            else
                echo "Error: Invalid style option: '-s $OPTARG'" 1>&2
                exit
            fi
            ;;
        i ) if [[ $OPTARG =~ ^[0-9]+$ ]]; then
                indentL=$OPTARG
            else
                echo "Error: Invalid indent value: '-i $OPTARG'" 1>&2
                exit
            fi
            ;;
        p ) if [[ $OPTARG =~ ^[0-9]+$ ]]; then
                paddingL=$OPTARG
                paddingR=$OPTARG
            else
                echo "Error: Invalid padding value: '-p $OPTARG'" 1>&2
                exit
            fi
            ;;
        t ) break
            ;;
        h ) usage_exit
            ;;
        v ) show_version
            ;;
        \?) echo "Please \"$0 -h\" to see help."
            exit
            ;;
    esac
done
shift $(($OPTIND - 1))

IFS_ORG="$IFS"
IFS=$'\n'

if [[ -p /dev/stdin ]]; then
    # pipe from command
    __str=$(cat -)
elif [[ -f /dev/stdin ]]; then
    # redirect from file
    __str=$(cat -)
elif [[ "$MSYSTEM" != "" && ! ( -t 0 ) ]]; then
    # pipe or redirect on MSYS (Windows)
    __str=$(cat -)
else
    usage_exit
    exit
fi

if [[ ${#__str} -eq 0 ]]; then
    exit
fi


# UTF-8 codes of the fullwidth characters from East Asian Width "F" & "W"
# http://www.unicode.org/Public/UCD/latest/ucd/EastAsianWidth.txt
EAW_F='
w1[1]="\xE1\x84\x80"; w2[1]="\xE1\x85\x9F"; # unicode 1100..115F
w1[2]="\xE2\x8C\x9A"; w2[2]="\xE2\x8C\x9B"; # unicode 231A..231B
w1[3]="\xE2\x8C\xA9"; w2[3]="\xE2\x8C\xAA"; # unicode 2329..232A
w1[4]="\xE2\x8F\xA9"; w2[4]="\xE2\x8F\xAC"; # unicode 23E9..23EC
w1[5]="\xE2\x8F\xB0"; w2[5]="\xE2\x8F\xB0"; # unicode 23F0
w1[6]="\xE2\x8F\xB3"; w2[6]="\xE2\x8F\xB3"; # unicode 23F3
w1[7]="\xE2\x97\xBD"; w2[7]="\xE2\x97\xBE"; # unicode 25FD..25FE
w1[8]="\xE2\x98\x94"; w2[8]="\xE2\x98\x95"; # unicode 2614..2615
w1[9]="\xE2\x99\x88"; w2[9]="\xE2\x99\x93"; # unicode 2648..2653
w1[10]="\xE2\x99\xBF"; w2[10]="\xE2\x99\xBF"; # unicode 267F
w1[11]="\xE2\x9A\x93"; w2[11]="\xE2\x9A\x93"; # unicode 2693
w1[12]="\xE2\x9A\xA1"; w2[12]="\xE2\x9A\xA1"; # unicode 26A1
w1[13]="\xE2\x9A\xAA"; w2[13]="\xE2\x9A\xAB"; # unicode 26AA..26AB
w1[14]="\xE2\x9A\xBD"; w2[14]="\xE2\x9A\xBE"; # unicode 26BD..26BE
w1[15]="\xE2\x9B\x84"; w2[15]="\xE2\x9B\x85"; # unicode 26C4..26C5
w1[16]="\xE2\x9B\x8E"; w2[16]="\xE2\x9B\x8E"; # unicode 26CE
w1[17]="\xE2\x9B\x94"; w2[17]="\xE2\x9B\x94"; # unicode 26D4
w1[18]="\xE2\x9B\xAA"; w2[18]="\xE2\x9B\xAA"; # unicode 26EA
w1[19]="\xE2\x9B\xB2"; w2[19]="\xE2\x9B\xB3"; # unicode 26F2..26F3
w1[20]="\xE2\x9B\xB5"; w2[20]="\xE2\x9B\xB5"; # unicode 26F5
w1[21]="\xE2\x9B\xBA"; w2[21]="\xE2\x9B\xBA"; # unicode 26FA
w1[22]="\xE2\x9B\xBD"; w2[22]="\xE2\x9B\xBD"; # unicode 26FD
w1[23]="\xE2\x9C\x85"; w2[23]="\xE2\x9C\x85"; # unicode 2705
w1[24]="\xE2\x9C\x8A"; w2[24]="\xE2\x9C\x8B"; # unicode 270A..270B
w1[25]="\xE2\x9C\xA8"; w2[25]="\xE2\x9C\xA8"; # unicode 2728
w1[26]="\xE2\x9D\x8C"; w2[26]="\xE2\x9D\x8C"; # unicode 274C
w1[27]="\xE2\x9D\x8E"; w2[27]="\xE2\x9D\x8E"; # unicode 274E
w1[28]="\xE2\x9D\x93"; w2[28]="\xE2\x9D\x95"; # unicode 2753..2755
w1[29]="\xE2\x9D\x97"; w2[29]="\xE2\x9D\x97"; # unicode 2757
w1[30]="\xE2\x9E\x95"; w2[30]="\xE2\x9E\x97"; # unicode 2795..2797
w1[31]="\xE2\x9E\xB0"; w2[31]="\xE2\x9E\xB0"; # unicode 27B0
w1[32]="\xE2\x9E\xBF"; w2[32]="\xE2\x9E\xBF"; # unicode 27BF
w1[33]="\xE2\xAC\x9B"; w2[33]="\xE2\xAC\x9C"; # unicode 2B1B..2B1C
w1[34]="\xE2\xAD\x90"; w2[34]="\xE2\xAD\x90"; # unicode 2B50
w1[35]="\xE2\xAD\x95"; w2[35]="\xE2\xAD\x95"; # unicode 2B55
w1[36]="\xE2\xBA\x80"; w2[36]="\xE2\xBA\x99"; # unicode 2E80..2E99
w1[37]="\xE2\xBA\x9B"; w2[37]="\xE2\xBB\xB3"; # unicode 2E9B..2EF3
w1[38]="\xE2\xBC\x80"; w2[38]="\xE2\xBF\x95"; # unicode 2F00..2FD5
w1[39]="\xE2\xBF\xB0"; w2[39]="\xE2\xBF\xBB"; # unicode 2FF0..2FFB
w1[40]="\xE3\x80\x80"; w2[40]="\xE3\x80\xBE"; # unicode 3000..303E
w1[41]="\xE3\x81\x81"; w2[41]="\xE3\x82\x96"; # unicode 3041..3096
w1[42]="\xE3\x82\x99"; w2[42]="\xE3\x83\xBF"; # unicode 3099..30FF
w1[43]="\xE3\x84\x85"; w2[43]="\xE3\x84\xAF"; # unicode 3105..312F
w1[44]="\xE3\x84\xB1"; w2[44]="\xE3\x86\x8E"; # unicode 3131..318E
w1[45]="\xE3\x86\x90"; w2[45]="\xE3\x86\xBA"; # unicode 3190..31BA
w1[46]="\xE3\x87\x80"; w2[46]="\xE3\x87\xA3"; # unicode 31C0..31E3
w1[47]="\xE3\x87\xB0"; w2[47]="\xE3\x88\x9E"; # unicode 31F0..321E
w1[48]="\xE3\x88\xA0"; w2[48]="\xE3\x89\x87"; # unicode 3220..3247
w1[49]="\xE3\x89\x90"; w2[49]="\xE3\x8B\xBE"; # unicode 3250..32FE
w1[50]="\xE3\x8C\x80"; w2[50]="\xE4\xB6\xBF"; # unicode 3300..4DBF
w1[51]="\xE4\xB8\x80"; w2[51]="\xEA\x92\x8C"; # unicode 4E00..A48C
w1[52]="\xEA\x92\x90"; w2[52]="\xEA\x93\x86"; # unicode A490..A4C6
w1[53]="\xEA\xA5\xA0"; w2[53]="\xEA\xA5\xBC"; # unicode A960..A97C
w1[54]="\xEA\xB0\x80"; w2[54]="\xED\x9E\xA3"; # unicode AC00..D7A3
w1[55]="\xEF\xA4\x80"; w2[55]="\xEF\xAB\xBF"; # unicode F900..FAFF
w1[56]="\xEF\xB8\x90"; w2[56]="\xEF\xB8\x99"; # unicode FE10..FE19
w1[57]="\xEF\xB8\xB0"; w2[57]="\xEF\xB9\x92"; # unicode FE30..FE52
w1[58]="\xEF\xB9\x94"; w2[58]="\xEF\xB9\xA6"; # unicode FE54..FE66
w1[59]="\xEF\xB9\xA8"; w2[59]="\xEF\xB9\xAB"; # unicode FE68..FE6B
w1[60]="\xEF\xBC\x81"; w2[60]="\xEF\xBD\xA0"; # unicode FF01..FF60
w1[61]="\xEF\xBF\xA0"; w2[61]="\xEF\xBF\xA6"; # unicode FFE0..FFE6
w1[62]="\xF0\x96\xBF\xA0"; w2[62]="\xF0\x96\xBF\xA1"; # unicode 16FE0..16FE1
w1[63]="\xF0\x97\x80\x80"; w2[63]="\xF0\x98\x9F\xB1"; # unicode 17000..187F1
w1[64]="\xF0\x98\xA0\x80"; w2[64]="\xF0\x98\xAB\xB2"; # unicode 18800..18AF2
w1[65]="\xF0\x9B\x80\x80"; w2[65]="\xF0\x9B\x84\x9E"; # unicode 1B000..1B11E
w1[66]="\xF0\x9B\x85\xB0"; w2[66]="\xF0\x9B\x8B\xBB"; # unicode 1B170..1B2FB
w1[67]="\xF0\x9F\x80\x84"; w2[67]="\xF0\x9F\x80\x84"; # unicode 1F004
w1[68]="\xF0\x9F\x83\x8F"; w2[68]="\xF0\x9F\x83\x8F"; # unicode 1F0CF
w1[69]="\xF0\x9F\x86\x8E"; w2[69]="\xF0\x9F\x86\x8E"; # unicode 1F18E
w1[70]="\xF0\x9F\x86\x91"; w2[70]="\xF0\x9F\x86\x9A"; # unicode 1F191..1F19A
w1[71]="\xF0\x9F\x88\x80"; w2[71]="\xF0\x9F\x88\x82"; # unicode 1F200..1F202
w1[72]="\xF0\x9F\x88\x90"; w2[72]="\xF0\x9F\x88\xBB"; # unicode 1F210..1F23B
w1[73]="\xF0\x9F\x89\x80"; w2[73]="\xF0\x9F\x89\x88"; # unicode 1F240..1F248
w1[74]="\xF0\x9F\x89\x90"; w2[74]="\xF0\x9F\x89\x91"; # unicode 1F250..1F251
w1[75]="\xF0\x9F\x89\xA0"; w2[75]="\xF0\x9F\x89\xA5"; # unicode 1F260..1F265
w1[76]="\xF0\x9F\x8C\x80"; w2[76]="\xF0\x9F\x8C\xA0"; # unicode 1F300..1F320
w1[77]="\xF0\x9F\x8C\xAD"; w2[77]="\xF0\x9F\x8C\xB5"; # unicode 1F32D..1F335
w1[78]="\xF0\x9F\x8C\xB7"; w2[78]="\xF0\x9F\x8D\xBC"; # unicode 1F337..1F37C
w1[79]="\xF0\x9F\x8D\xBE"; w2[79]="\xF0\x9F\x8E\x93"; # unicode 1F37E..1F393
w1[80]="\xF0\x9F\x8E\xA0"; w2[80]="\xF0\x9F\x8F\x8A"; # unicode 1F3A0..1F3CA
w1[81]="\xF0\x9F\x8F\x8F"; w2[81]="\xF0\x9F\x8F\x93"; # unicode 1F3CF..1F3D3
w1[82]="\xF0\x9F\x8F\xA0"; w2[82]="\xF0\x9F\x8F\xB0"; # unicode 1F3E0..1F3F0
w1[83]="\xF0\x9F\x8F\xB4"; w2[83]="\xF0\x9F\x8F\xB4"; # unicode 1F3F4
w1[84]="\xF0\x9F\x8F\xB8"; w2[84]="\xF0\x9F\x90\xBE"; # unicode 1F3F8..1F43E
w1[85]="\xF0\x9F\x91\x80"; w2[85]="\xF0\x9F\x91\x80"; # unicode 1F440
w1[86]="\xF0\x9F\x91\x82"; w2[86]="\xF0\x9F\x93\xBC"; # unicode 1F442..1F4FC
w1[87]="\xF0\x9F\x93\xBF"; w2[87]="\xF0\x9F\x94\xBD"; # unicode 1F4FF..1F53D
w1[88]="\xF0\x9F\x95\x8B"; w2[88]="\xF0\x9F\x95\x8E"; # unicode 1F54B..1F54E
w1[89]="\xF0\x9F\x95\x90"; w2[89]="\xF0\x9F\x95\xA7"; # unicode 1F550..1F567
w1[90]="\xF0\x9F\x95\xBA"; w2[90]="\xF0\x9F\x95\xBA"; # unicode 1F57A
w1[91]="\xF0\x9F\x96\x95"; w2[91]="\xF0\x9F\x96\x96"; # unicode 1F595..1F596
w1[92]="\xF0\x9F\x96\xA4"; w2[92]="\xF0\x9F\x96\xA4"; # unicode 1F5A4
w1[93]="\xF0\x9F\x97\xBB"; w2[93]="\xF0\x9F\x99\x8F"; # unicode 1F5FB..1F64F
w1[94]="\xF0\x9F\x9A\x80"; w2[94]="\xF0\x9F\x9B\x85"; # unicode 1F680..1F6C5
w1[95]="\xF0\x9F\x9B\x8C"; w2[95]="\xF0\x9F\x9B\x8C"; # unicode 1F6CC
w1[96]="\xF0\x9F\x9B\x90"; w2[96]="\xF0\x9F\x9B\x92"; # unicode 1F6D0..1F6D2
w1[97]="\xF0\x9F\x9B\xAB"; w2[97]="\xF0\x9F\x9B\xAC"; # unicode 1F6EB..1F6EC
w1[98]="\xF0\x9F\x9B\xB4"; w2[98]="\xF0\x9F\x9B\xB9"; # unicode 1F6F4..1F6F9
w1[99]="\xF0\x9F\xA4\x90"; w2[99]="\xF0\x9F\xA4\xBE"; # unicode 1F910..1F93E
w1[100]="\xF0\x9F\xA5\x80"; w2[100]="\xF0\x9F\xA5\xB0"; # unicode 1F940..1F970
w1[101]="\xF0\x9F\xA5\xB3"; w2[101]="\xF0\x9F\xA5\xB6"; # unicode 1F973..1F976
w1[102]="\xF0\x9F\xA5\xBA"; w2[102]="\xF0\x9F\xA5\xBA"; # unicode 1F97A
w1[103]="\xF0\x9F\xA5\xBC"; w2[103]="\xF0\x9F\xA6\xA2"; # unicode 1F97C..1F9A2
w1[104]="\xF0\x9F\xA6\xB0"; w2[104]="\xF0\x9F\xA6\xB9"; # unicode 1F9B0..1F9B9
w1[105]="\xF0\x9F\xA7\x80"; w2[105]="\xF0\x9F\xA7\x82"; # unicode 1F9C0..1F9C2
w1[106]="\xF0\x9F\xA7\x90"; w2[106]="\xF0\x9F\xA7\xBF"; # unicode 1F9D0..1F9FF
w1[107]="\xF0\xA0\x80\x80"; w2[107]="\xF0\xAF\xBF\xBD"; # unicode 20000..2FFFD
w1[108]="\xF0\xB0\x80\x80"; w2[108]="\xF0\xBF\xBF\xBD"; # unicode 30000..3FFFD
'

unset COL_TITLE
for i in "$@"
do
    COL_TITLE="${COL_TITLE}\"$i\","
done
COL_TITLE=$(echo ${COL_TITLE%,})

__arr=(${__str[*]})
if [ ! -z "${COL_TITLE[*]}" ]; then
    __arr=("${COL_TITLE[*]}" "${__arr[*]}")
fi


# determine column width
__colwid=( $(
  echo "${__arr[*]}" | \
  gawk -b -v padL="${paddingL}" -v padR="${paddingR}" \
  'BEGIN {
  '"${EAW_F[*]}"' ### INCLUDE FULLWIDTH CHARACTER LIST ###
  }
  function chrwidth(uchr,i) {
    for(i=1;i<=108;i++) {
      if(w1[i]>uchr) return 1;  # uchr is halfwidth
      if(w2[i]>=uchr) return 2; # uchr is fullwidth
    };
    return 1;
  }
  function strwidth(ustr,i,l) {
    patsplit(ustr,s_arr,"([\x00-\x7F])|(([\xC2-\xDE]|\xDF)[\x80-\xBF])|([\xE0-\xEF][\x80-\xBF]{2})|([\xF0-\xF7][\x80-\xBF]{3})");
  l=0;
  for(i=1;i<=length(s_arr);i++) {
    l=l+chrwidth(s_arr[i]);};
    return l;
  }
  { gsub(/^\xEF\xBB\xBF/,"",$0); gsub(/,/," , ",$0); }
  { patsplit($0,arr,"([^,]+)|( *\"[^\"]+\" *)");
    for (i=1; i<=length(arr); i++) {
      col=arr[i];
      gsub(/ , /,",",col);
      gsub(/\\\\/,"\a",col);
      gsub(/\\/,"",col);
      gsub(/\a/,"\\",col);
      gsub(/[[:cntrl:]]+/,"",col);
      gsub(/^ +/,"",col);
      gsub(/ +$/,"",col);
      col=gensub(/^\"([^\n]*)\"$/,"\\1","g",col);
      n=strwidth(col)+padL+padR;
      if ( length(collen[i]) < 1 ) collen[i]=n;
      else if ( collen[i] < n ) collen[i]=n;
    }
  }
  END { if (length(collen) > 0) {
      for (i=1; i<=length(collen); i++) {
        print collen[i];
      }
    }
  }' ) )

if [[ ${#__colwid} == 0 ]]; then
    IFS="$IFS_ORG"
    exit
fi


# print table
  echo "${__arr[*]}" | \
  gawk -b \
  -v padL="${paddingL}" -v padR="${paddingR}" -v indentL="${indentL}" \
  -v colwid="${__colwid[*]}" -v colalign="${COLALIGN[*]}" \
  -v border="${TBL_STYLE}" \
   'BEGIN {
   '"${EAW_F[*]}"' ### INCLUDE FULLWIDTH CHARACTER LIST ###
      line = 0;
      split(colwid,wid);
      split(colalign,align);
    }
    function chrwidth(uchr,i) {
      for(i=1;i<=108;i++) {
        if(w1[i]>uchr) return 1;  # uchr is halfwidth
        if(w2[i]>=uchr) return 2; # uchr is fullwidth
      };
      return 1;
    }
    function strwidth(ustr,i,l) {
      patsplit(ustr,s_arr,"([\x00-\x7F])|(([\xC2-\xDE]|\xDF)[\x80-\xBF])|([\xE0-\xEF][\x80-\xBF]{2})|([\xF0-\xF7][\x80-\xBF]{3})");
    l=0;
    for(i=1;i<=length(s_arr);i++) {
      l=l+chrwidth(s_arr[i]);};
      return l;
    }
    { gsub(/^\xEF\xBB\xBF/,"",$0); gsub(/,/," , ",$0); }
    { patsplit($0,arr,"([^,]+)|( *\"[^\"]+\" *)");
      if ((line==0 && border>0)|| (line==1 && border>1) || border==3) {
        printf("%"indentL"s", "");
        for (i=1; i<=length(wid); i++) {
          x="+";
          for (j=0; j<wid[i]; j++) x=x"-";
          printf x;
        }
        print "+";
      }
      line++;
      printf("%"indentL"s", "");
      for (i=1; i<=length(wid); i++) {
        col=arr[i];
        gsub(/ , /,",",col);
        gsub(/\\\\/,"\a",col);
        gsub(/\\/,"",col);
        gsub(/\a/,"\\",col);
        gsub(/[[:cntrl:]]+/,"",col);
        gsub(/^ +/,"",col);
        gsub(/ +$/,"",col);
        col=gensub(/^\"([^\n]*)\"$/,"\\1","g",col);
        n=strwidth(col);
        if (length(align[i]) == 0) {
          nl=padL;
        } else if (align[i] == "r") {
          nl=wid[i]-n-padR;
        } else if (align[i] == "c") {
          nl=int((wid[i]-n)/2);
        } else {
          nl=padL;
        }
        nr=wid[i]-n-nl;
        if (border>0)
          printf("|");
        else
          printf(" ");
        if (nl>0) {
          printf("%"nl"s", " ");
        }
        printf("%s",col);
        if (nr>0) {
          printf("%"nr"s", " ");
        }
      }
      if (border>0)
        print "|";
      else
        print " ";
    }
    END {
      if (border>0) {
        printf("%"indentL"s", "");
        for (i=1; i<=length(wid); i++) {
          x="+";
          for (j=0; j<wid[i]; j++) x=x"-";
          printf x;
        }
        print "+"
      }
    }
   '
IFS="$IFS_ORG"
