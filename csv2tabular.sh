#! /bin/bash

# This script requires GNU Awk 4.0 or later.
#
# version 1.1.0: fix the following warning for gawk 5.0
#   gawk: cmd. line:139: warning: regexp escape sequence `\"' is not a known regexp operator
#   gawk: cmd. line:153: warning: regexp escape sequence `\"' is not a known regexp operator
#
# version 1.0.1: first release

VERSION_AND_LICENSE="
csv2tabular.sh  1.1.0
Copyright (C) 2020 kitanokitsune

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
  -w                  Treat the East Asian Ambiguous characters as Fullwidth.
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
EAAW=1
COLALIGN=()

while getopts lrcs:i:p:twvh OPT
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
        w ) EAAW=2
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
if [ $EAAW -eq 2 ]; then
EAW_F='
wlen=262;
w1[1]="\xC2\xA1"; w2[1]="\xC2\xA1"; # uni 00A1
w1[2]="\xC2\xA4"; w2[2]="\xC2\xA4"; # uni 00A4
w1[3]="\xC2\xA7"; w2[3]="\xC2\xA8"; # uni 00A7..00A8
w1[4]="\xC2\xAA"; w2[4]="\xC2\xAA"; # uni 00AA
w1[5]="\xC2\xAD"; w2[5]="\xC2\xAE"; # uni 00AD..00AE
w1[6]="\xC2\xB0"; w2[6]="\xC2\xB4"; # uni 00B0..00B4
w1[7]="\xC2\xB6"; w2[7]="\xC2\xBA"; # uni 00B6..00BA
w1[8]="\xC2\xBC"; w2[8]="\xC2\xBF"; # uni 00BC..00BF
w1[9]="\xC3\x86"; w2[9]="\xC3\x86"; # uni 00C6
w1[10]="\xC3\x90"; w2[10]="\xC3\x90"; # uni 00D0
w1[11]="\xC3\x97"; w2[11]="\xC3\x98"; # uni 00D7..00D8
w1[12]="\xC3\x9E"; w2[12]="\xC3\xA1"; # uni 00DE..00E1
w1[13]="\xC3\xA6"; w2[13]="\xC3\xA6"; # uni 00E6
w1[14]="\xC3\xA8"; w2[14]="\xC3\xAA"; # uni 00E8..00EA
w1[15]="\xC3\xAC"; w2[15]="\xC3\xAD"; # uni 00EC..00ED
w1[16]="\xC3\xB0"; w2[16]="\xC3\xB0"; # uni 00F0
w1[17]="\xC3\xB2"; w2[17]="\xC3\xB3"; # uni 00F2..00F3
w1[18]="\xC3\xB7"; w2[18]="\xC3\xBA"; # uni 00F7..00FA
w1[19]="\xC3\xBC"; w2[19]="\xC3\xBC"; # uni 00FC
w1[20]="\xC3\xBE"; w2[20]="\xC3\xBE"; # uni 00FE
w1[21]="\xC4\x81"; w2[21]="\xC4\x81"; # uni 0101
w1[22]="\xC4\x91"; w2[22]="\xC4\x91"; # uni 0111
w1[23]="\xC4\x93"; w2[23]="\xC4\x93"; # uni 0113
w1[24]="\xC4\x9B"; w2[24]="\xC4\x9B"; # uni 011B
w1[25]="\xC4\xA6"; w2[25]="\xC4\xA7"; # uni 0126..0127
w1[26]="\xC4\xAB"; w2[26]="\xC4\xAB"; # uni 012B
w1[27]="\xC4\xB1"; w2[27]="\xC4\xB3"; # uni 0131..0133
w1[28]="\xC4\xB8"; w2[28]="\xC4\xB8"; # uni 0138
w1[29]="\xC4\xBF"; w2[29]="\xC5\x82"; # uni 013F..0142
w1[30]="\xC5\x84"; w2[30]="\xC5\x84"; # uni 0144
w1[31]="\xC5\x88"; w2[31]="\xC5\x8B"; # uni 0148..014B
w1[32]="\xC5\x8D"; w2[32]="\xC5\x8D"; # uni 014D
w1[33]="\xC5\x92"; w2[33]="\xC5\x93"; # uni 0152..0153
w1[34]="\xC5\xA6"; w2[34]="\xC5\xA7"; # uni 0166..0167
w1[35]="\xC5\xAB"; w2[35]="\xC5\xAB"; # uni 016B
w1[36]="\xC7\x8E"; w2[36]="\xC7\x8E"; # uni 01CE
w1[37]="\xC7\x90"; w2[37]="\xC7\x90"; # uni 01D0
w1[38]="\xC7\x92"; w2[38]="\xC7\x92"; # uni 01D2
w1[39]="\xC7\x94"; w2[39]="\xC7\x94"; # uni 01D4
w1[40]="\xC7\x96"; w2[40]="\xC7\x96"; # uni 01D6
w1[41]="\xC7\x98"; w2[41]="\xC7\x98"; # uni 01D8
w1[42]="\xC7\x9A"; w2[42]="\xC7\x9A"; # uni 01DA
w1[43]="\xC7\x9C"; w2[43]="\xC7\x9C"; # uni 01DC
w1[44]="\xC9\x91"; w2[44]="\xC9\x91"; # uni 0251
w1[45]="\xC9\xA1"; w2[45]="\xC9\xA1"; # uni 0261
w1[46]="\xCB\x84"; w2[46]="\xCB\x84"; # uni 02C4
w1[47]="\xCB\x87"; w2[47]="\xCB\x87"; # uni 02C7
w1[48]="\xCB\x89"; w2[48]="\xCB\x8B"; # uni 02C9..02CB
w1[49]="\xCB\x8D"; w2[49]="\xCB\x8D"; # uni 02CD
w1[50]="\xCB\x90"; w2[50]="\xCB\x90"; # uni 02D0
w1[51]="\xCB\x98"; w2[51]="\xCB\x9B"; # uni 02D8..02DB
w1[52]="\xCB\x9D"; w2[52]="\xCB\x9D"; # uni 02DD
w1[53]="\xCB\x9F"; w2[53]="\xCB\x9F"; # uni 02DF
w1[54]="\xCC\x80"; w2[54]="\xCD\xAF"; # uni 0300..036F
w1[55]="\xCE\x91"; w2[55]="\xCE\xA1"; # uni 0391..03A1
w1[56]="\xCE\xA3"; w2[56]="\xCE\xA9"; # uni 03A3..03A9
w1[57]="\xCE\xB1"; w2[57]="\xCF\x81"; # uni 03B1..03C1
w1[58]="\xCF\x83"; w2[58]="\xCF\x89"; # uni 03C3..03C9
w1[59]="\xD0\x81"; w2[59]="\xD0\x81"; # uni 0401
w1[60]="\xD0\x90"; w2[60]="\xD1\x8F"; # uni 0410..044F
w1[61]="\xD1\x91"; w2[61]="\xD1\x91"; # uni 0451
w1[62]="\xE1\x84\x80"; w2[62]="\xE1\x85\x9F"; # uni 1100..115F
w1[63]="\xE2\x80\x90"; w2[63]="\xE2\x80\x90"; # uni 2010
w1[64]="\xE2\x80\x93"; w2[64]="\xE2\x80\x96"; # uni 2013..2016
w1[65]="\xE2\x80\x98"; w2[65]="\xE2\x80\x99"; # uni 2018..2019
w1[66]="\xE2\x80\x9C"; w2[66]="\xE2\x80\x9D"; # uni 201C..201D
w1[67]="\xE2\x80\xA0"; w2[67]="\xE2\x80\xA2"; # uni 2020..2022
w1[68]="\xE2\x80\xA4"; w2[68]="\xE2\x80\xA7"; # uni 2024..2027
w1[69]="\xE2\x80\xB0"; w2[69]="\xE2\x80\xB0"; # uni 2030
w1[70]="\xE2\x80\xB2"; w2[70]="\xE2\x80\xB3"; # uni 2032..2033
w1[71]="\xE2\x80\xB5"; w2[71]="\xE2\x80\xB5"; # uni 2035
w1[72]="\xE2\x80\xBB"; w2[72]="\xE2\x80\xBB"; # uni 203B
w1[73]="\xE2\x80\xBE"; w2[73]="\xE2\x80\xBE"; # uni 203E
w1[74]="\xE2\x81\xB4"; w2[74]="\xE2\x81\xB4"; # uni 2074
w1[75]="\xE2\x81\xBF"; w2[75]="\xE2\x81\xBF"; # uni 207F
w1[76]="\xE2\x82\x81"; w2[76]="\xE2\x82\x84"; # uni 2081..2084
w1[77]="\xE2\x82\xAC"; w2[77]="\xE2\x82\xAC"; # uni 20AC
w1[78]="\xE2\x84\x83"; w2[78]="\xE2\x84\x83"; # uni 2103
w1[79]="\xE2\x84\x85"; w2[79]="\xE2\x84\x85"; # uni 2105
w1[80]="\xE2\x84\x89"; w2[80]="\xE2\x84\x89"; # uni 2109
w1[81]="\xE2\x84\x93"; w2[81]="\xE2\x84\x93"; # uni 2113
w1[82]="\xE2\x84\x96"; w2[82]="\xE2\x84\x96"; # uni 2116
w1[83]="\xE2\x84\xA1"; w2[83]="\xE2\x84\xA2"; # uni 2121..2122
w1[84]="\xE2\x84\xA6"; w2[84]="\xE2\x84\xA6"; # uni 2126
w1[85]="\xE2\x84\xAB"; w2[85]="\xE2\x84\xAB"; # uni 212B
w1[86]="\xE2\x85\x93"; w2[86]="\xE2\x85\x94"; # uni 2153..2154
w1[87]="\xE2\x85\x9B"; w2[87]="\xE2\x85\x9E"; # uni 215B..215E
w1[88]="\xE2\x85\xA0"; w2[88]="\xE2\x85\xAB"; # uni 2160..216B
w1[89]="\xE2\x85\xB0"; w2[89]="\xE2\x85\xB9"; # uni 2170..2179
w1[90]="\xE2\x86\x89"; w2[90]="\xE2\x86\x89"; # uni 2189
w1[91]="\xE2\x86\x90"; w2[91]="\xE2\x86\x99"; # uni 2190..2199
w1[92]="\xE2\x86\xB8"; w2[92]="\xE2\x86\xB9"; # uni 21B8..21B9
w1[93]="\xE2\x87\x92"; w2[93]="\xE2\x87\x92"; # uni 21D2
w1[94]="\xE2\x87\x94"; w2[94]="\xE2\x87\x94"; # uni 21D4
w1[95]="\xE2\x87\xA7"; w2[95]="\xE2\x87\xA7"; # uni 21E7
w1[96]="\xE2\x88\x80"; w2[96]="\xE2\x88\x80"; # uni 2200
w1[97]="\xE2\x88\x82"; w2[97]="\xE2\x88\x83"; # uni 2202..2203
w1[98]="\xE2\x88\x87"; w2[98]="\xE2\x88\x88"; # uni 2207..2208
w1[99]="\xE2\x88\x8B"; w2[99]="\xE2\x88\x8B"; # uni 220B
w1[100]="\xE2\x88\x8F"; w2[100]="\xE2\x88\x8F"; # uni 220F
w1[101]="\xE2\x88\x91"; w2[101]="\xE2\x88\x91"; # uni 2211
w1[102]="\xE2\x88\x95"; w2[102]="\xE2\x88\x95"; # uni 2215
w1[103]="\xE2\x88\x9A"; w2[103]="\xE2\x88\x9A"; # uni 221A
w1[104]="\xE2\x88\x9D"; w2[104]="\xE2\x88\xA0"; # uni 221D..2220
w1[105]="\xE2\x88\xA3"; w2[105]="\xE2\x88\xA3"; # uni 2223
w1[106]="\xE2\x88\xA5"; w2[106]="\xE2\x88\xA5"; # uni 2225
w1[107]="\xE2\x88\xA7"; w2[107]="\xE2\x88\xAC"; # uni 2227..222C
w1[108]="\xE2\x88\xAE"; w2[108]="\xE2\x88\xAE"; # uni 222E
w1[109]="\xE2\x88\xB4"; w2[109]="\xE2\x88\xB7"; # uni 2234..2237
w1[110]="\xE2\x88\xBC"; w2[110]="\xE2\x88\xBD"; # uni 223C..223D
w1[111]="\xE2\x89\x88"; w2[111]="\xE2\x89\x88"; # uni 2248
w1[112]="\xE2\x89\x8C"; w2[112]="\xE2\x89\x8C"; # uni 224C
w1[113]="\xE2\x89\x92"; w2[113]="\xE2\x89\x92"; # uni 2252
w1[114]="\xE2\x89\xA0"; w2[114]="\xE2\x89\xA1"; # uni 2260..2261
w1[115]="\xE2\x89\xA4"; w2[115]="\xE2\x89\xA7"; # uni 2264..2267
w1[116]="\xE2\x89\xAA"; w2[116]="\xE2\x89\xAB"; # uni 226A..226B
w1[117]="\xE2\x89\xAE"; w2[117]="\xE2\x89\xAF"; # uni 226E..226F
w1[118]="\xE2\x8A\x82"; w2[118]="\xE2\x8A\x83"; # uni 2282..2283
w1[119]="\xE2\x8A\x86"; w2[119]="\xE2\x8A\x87"; # uni 2286..2287
w1[120]="\xE2\x8A\x95"; w2[120]="\xE2\x8A\x95"; # uni 2295
w1[121]="\xE2\x8A\x99"; w2[121]="\xE2\x8A\x99"; # uni 2299
w1[122]="\xE2\x8A\xA5"; w2[122]="\xE2\x8A\xA5"; # uni 22A5
w1[123]="\xE2\x8A\xBF"; w2[123]="\xE2\x8A\xBF"; # uni 22BF
w1[124]="\xE2\x8C\x92"; w2[124]="\xE2\x8C\x92"; # uni 2312
w1[125]="\xE2\x8C\x9A"; w2[125]="\xE2\x8C\x9B"; # uni 231A..231B
w1[126]="\xE2\x8C\xA9"; w2[126]="\xE2\x8C\xAA"; # uni 2329..232A
w1[127]="\xE2\x8F\xA9"; w2[127]="\xE2\x8F\xAC"; # uni 23E9..23EC
w1[128]="\xE2\x8F\xB0"; w2[128]="\xE2\x8F\xB0"; # uni 23F0
w1[129]="\xE2\x8F\xB3"; w2[129]="\xE2\x8F\xB3"; # uni 23F3
w1[130]="\xE2\x91\xA0"; w2[130]="\xE2\x93\xA9"; # uni 2460..24E9
w1[131]="\xE2\x93\xAB"; w2[131]="\xE2\x95\x8B"; # uni 24EB..254B
w1[132]="\xE2\x95\x90"; w2[132]="\xE2\x95\xB3"; # uni 2550..2573
w1[133]="\xE2\x96\x80"; w2[133]="\xE2\x96\x8F"; # uni 2580..258F
w1[134]="\xE2\x96\x92"; w2[134]="\xE2\x96\x95"; # uni 2592..2595
w1[135]="\xE2\x96\xA0"; w2[135]="\xE2\x96\xA1"; # uni 25A0..25A1
w1[136]="\xE2\x96\xA3"; w2[136]="\xE2\x96\xA9"; # uni 25A3..25A9
w1[137]="\xE2\x96\xB2"; w2[137]="\xE2\x96\xB3"; # uni 25B2..25B3
w1[138]="\xE2\x96\xB6"; w2[138]="\xE2\x96\xB7"; # uni 25B6..25B7
w1[139]="\xE2\x96\xBC"; w2[139]="\xE2\x96\xBD"; # uni 25BC..25BD
w1[140]="\xE2\x97\x80"; w2[140]="\xE2\x97\x81"; # uni 25C0..25C1
w1[141]="\xE2\x97\x86"; w2[141]="\xE2\x97\x88"; # uni 25C6..25C8
w1[142]="\xE2\x97\x8B"; w2[142]="\xE2\x97\x8B"; # uni 25CB
w1[143]="\xE2\x97\x8E"; w2[143]="\xE2\x97\x91"; # uni 25CE..25D1
w1[144]="\xE2\x97\xA2"; w2[144]="\xE2\x97\xA5"; # uni 25E2..25E5
w1[145]="\xE2\x97\xAF"; w2[145]="\xE2\x97\xAF"; # uni 25EF
w1[146]="\xE2\x97\xBD"; w2[146]="\xE2\x97\xBE"; # uni 25FD..25FE
w1[147]="\xE2\x98\x85"; w2[147]="\xE2\x98\x86"; # uni 2605..2606
w1[148]="\xE2\x98\x89"; w2[148]="\xE2\x98\x89"; # uni 2609
w1[149]="\xE2\x98\x8E"; w2[149]="\xE2\x98\x8F"; # uni 260E..260F
w1[150]="\xE2\x98\x94"; w2[150]="\xE2\x98\x95"; # uni 2614..2615
w1[151]="\xE2\x98\x9C"; w2[151]="\xE2\x98\x9C"; # uni 261C
w1[152]="\xE2\x98\x9E"; w2[152]="\xE2\x98\x9E"; # uni 261E
w1[153]="\xE2\x99\x80"; w2[153]="\xE2\x99\x80"; # uni 2640
w1[154]="\xE2\x99\x82"; w2[154]="\xE2\x99\x82"; # uni 2642
w1[155]="\xE2\x99\x88"; w2[155]="\xE2\x99\x93"; # uni 2648..2653
w1[156]="\xE2\x99\xA0"; w2[156]="\xE2\x99\xA1"; # uni 2660..2661
w1[157]="\xE2\x99\xA3"; w2[157]="\xE2\x99\xA5"; # uni 2663..2665
w1[158]="\xE2\x99\xA7"; w2[158]="\xE2\x99\xAA"; # uni 2667..266A
w1[159]="\xE2\x99\xAC"; w2[159]="\xE2\x99\xAD"; # uni 266C..266D
w1[160]="\xE2\x99\xAF"; w2[160]="\xE2\x99\xAF"; # uni 266F
w1[161]="\xE2\x99\xBF"; w2[161]="\xE2\x99\xBF"; # uni 267F
w1[162]="\xE2\x9A\x93"; w2[162]="\xE2\x9A\x93"; # uni 2693
w1[163]="\xE2\x9A\x9E"; w2[163]="\xE2\x9A\x9F"; # uni 269E..269F
w1[164]="\xE2\x9A\xA1"; w2[164]="\xE2\x9A\xA1"; # uni 26A1
w1[165]="\xE2\x9A\xAA"; w2[165]="\xE2\x9A\xAB"; # uni 26AA..26AB
w1[166]="\xE2\x9A\xBD"; w2[166]="\xE2\x9A\xBF"; # uni 26BD..26BF
w1[167]="\xE2\x9B\x84"; w2[167]="\xE2\x9B\xA1"; # uni 26C4..26E1
w1[168]="\xE2\x9B\xA3"; w2[168]="\xE2\x9B\xA3"; # uni 26E3
w1[169]="\xE2\x9B\xA8"; w2[169]="\xE2\x9B\xBF"; # uni 26E8..26FF
w1[170]="\xE2\x9C\x85"; w2[170]="\xE2\x9C\x85"; # uni 2705
w1[171]="\xE2\x9C\x8A"; w2[171]="\xE2\x9C\x8B"; # uni 270A..270B
w1[172]="\xE2\x9C\xA8"; w2[172]="\xE2\x9C\xA8"; # uni 2728
w1[173]="\xE2\x9C\xBD"; w2[173]="\xE2\x9C\xBD"; # uni 273D
w1[174]="\xE2\x9D\x8C"; w2[174]="\xE2\x9D\x8C"; # uni 274C
w1[175]="\xE2\x9D\x8E"; w2[175]="\xE2\x9D\x8E"; # uni 274E
w1[176]="\xE2\x9D\x93"; w2[176]="\xE2\x9D\x95"; # uni 2753..2755
w1[177]="\xE2\x9D\x97"; w2[177]="\xE2\x9D\x97"; # uni 2757
w1[178]="\xE2\x9D\xB6"; w2[178]="\xE2\x9D\xBF"; # uni 2776..277F
w1[179]="\xE2\x9E\x95"; w2[179]="\xE2\x9E\x97"; # uni 2795..2797
w1[180]="\xE2\x9E\xB0"; w2[180]="\xE2\x9E\xB0"; # uni 27B0
w1[181]="\xE2\x9E\xBF"; w2[181]="\xE2\x9E\xBF"; # uni 27BF
w1[182]="\xE2\xAC\x9B"; w2[182]="\xE2\xAC\x9C"; # uni 2B1B..2B1C
w1[183]="\xE2\xAD\x90"; w2[183]="\xE2\xAD\x90"; # uni 2B50
w1[184]="\xE2\xAD\x95"; w2[184]="\xE2\xAD\x99"; # uni 2B55..2B59
w1[185]="\xE2\xBA\x80"; w2[185]="\xE2\xBA\x99"; # uni 2E80..2E99
w1[186]="\xE2\xBA\x9B"; w2[186]="\xE2\xBB\xB3"; # uni 2E9B..2EF3
w1[187]="\xE2\xBC\x80"; w2[187]="\xE2\xBF\x95"; # uni 2F00..2FD5
w1[188]="\xE2\xBF\xB0"; w2[188]="\xE2\xBF\xBB"; # uni 2FF0..2FFB
w1[189]="\xE3\x80\x80"; w2[189]="\xE3\x80\xBE"; # uni 3000..303E
w1[190]="\xE3\x81\x81"; w2[190]="\xE3\x82\x96"; # uni 3041..3096
w1[191]="\xE3\x82\x99"; w2[191]="\xE3\x83\xBF"; # uni 3099..30FF
w1[192]="\xE3\x84\x85"; w2[192]="\xE3\x84\xAF"; # uni 3105..312F
w1[193]="\xE3\x84\xB1"; w2[193]="\xE3\x86\x8E"; # uni 3131..318E
w1[194]="\xE3\x86\x90"; w2[194]="\xE3\x86\xBA"; # uni 3190..31BA
w1[195]="\xE3\x87\x80"; w2[195]="\xE3\x87\xA3"; # uni 31C0..31E3
w1[196]="\xE3\x87\xB0"; w2[196]="\xE3\x88\x9E"; # uni 31F0..321E
w1[197]="\xE3\x88\xA0"; w2[197]="\xE3\x8B\xBE"; # uni 3220..32FE
w1[198]="\xE3\x8C\x80"; w2[198]="\xE4\xB6\xBF"; # uni 3300..4DBF
w1[199]="\xE4\xB8\x80"; w2[199]="\xEA\x92\x8C"; # uni 4E00..A48C
w1[200]="\xEA\x92\x90"; w2[200]="\xEA\x93\x86"; # uni A490..A4C6
w1[201]="\xEA\xA5\xA0"; w2[201]="\xEA\xA5\xBC"; # uni A960..A97C
w1[202]="\xEA\xB0\x80"; w2[202]="\xED\x9E\xA3"; # uni AC00..D7A3
w1[203]="\xEE\x80\x80"; w2[203]="\xEF\xAB\xBF"; # uni E000..FAFF
w1[204]="\xEF\xB8\x80"; w2[204]="\xEF\xB8\x99"; # uni FE00..FE19
w1[205]="\xEF\xB8\xB0"; w2[205]="\xEF\xB9\x92"; # uni FE30..FE52
w1[206]="\xEF\xB9\x94"; w2[206]="\xEF\xB9\xA6"; # uni FE54..FE66
w1[207]="\xEF\xB9\xA8"; w2[207]="\xEF\xB9\xAB"; # uni FE68..FE6B
w1[208]="\xEF\xBC\x81"; w2[208]="\xEF\xBD\xA0"; # uni FF01..FF60
w1[209]="\xEF\xBF\xA0"; w2[209]="\xEF\xBF\xA6"; # uni FFE0..FFE6
w1[210]="\xEF\xBF\xBD"; w2[210]="\xEF\xBF\xBD"; # uni FFFD
w1[211]="\xF0\x96\xBF\xA0"; w2[211]="\xF0\x96\xBF\xA1"; # uni 16FE0..16FE1
w1[212]="\xF0\x97\x80\x80"; w2[212]="\xF0\x98\x9F\xB1"; # uni 17000..187F1
w1[213]="\xF0\x98\xA0\x80"; w2[213]="\xF0\x98\xAB\xB2"; # uni 18800..18AF2
w1[214]="\xF0\x9B\x80\x80"; w2[214]="\xF0\x9B\x84\x9E"; # uni 1B000..1B11E
w1[215]="\xF0\x9B\x85\xB0"; w2[215]="\xF0\x9B\x8B\xBB"; # uni 1B170..1B2FB
w1[216]="\xF0\x9F\x80\x84"; w2[216]="\xF0\x9F\x80\x84"; # uni 1F004
w1[217]="\xF0\x9F\x83\x8F"; w2[217]="\xF0\x9F\x83\x8F"; # uni 1F0CF
w1[218]="\xF0\x9F\x84\x80"; w2[218]="\xF0\x9F\x84\x8A"; # uni 1F100..1F10A
w1[219]="\xF0\x9F\x84\x90"; w2[219]="\xF0\x9F\x84\xAD"; # uni 1F110..1F12D
w1[220]="\xF0\x9F\x84\xB0"; w2[220]="\xF0\x9F\x85\xA9"; # uni 1F130..1F169
w1[221]="\xF0\x9F\x85\xB0"; w2[221]="\xF0\x9F\x86\xAC"; # uni 1F170..1F1AC
w1[222]="\xF0\x9F\x88\x80"; w2[222]="\xF0\x9F\x88\x82"; # uni 1F200..1F202
w1[223]="\xF0\x9F\x88\x90"; w2[223]="\xF0\x9F\x88\xBB"; # uni 1F210..1F23B
w1[224]="\xF0\x9F\x89\x80"; w2[224]="\xF0\x9F\x89\x88"; # uni 1F240..1F248
w1[225]="\xF0\x9F\x89\x90"; w2[225]="\xF0\x9F\x89\x91"; # uni 1F250..1F251
w1[226]="\xF0\x9F\x89\xA0"; w2[226]="\xF0\x9F\x89\xA5"; # uni 1F260..1F265
w1[227]="\xF0\x9F\x8C\x80"; w2[227]="\xF0\x9F\x8C\xA0"; # uni 1F300..1F320
w1[228]="\xF0\x9F\x8C\xAD"; w2[228]="\xF0\x9F\x8C\xB5"; # uni 1F32D..1F335
w1[229]="\xF0\x9F\x8C\xB7"; w2[229]="\xF0\x9F\x8D\xBC"; # uni 1F337..1F37C
w1[230]="\xF0\x9F\x8D\xBE"; w2[230]="\xF0\x9F\x8E\x93"; # uni 1F37E..1F393
w1[231]="\xF0\x9F\x8E\xA0"; w2[231]="\xF0\x9F\x8F\x8A"; # uni 1F3A0..1F3CA
w1[232]="\xF0\x9F\x8F\x8F"; w2[232]="\xF0\x9F\x8F\x93"; # uni 1F3CF..1F3D3
w1[233]="\xF0\x9F\x8F\xA0"; w2[233]="\xF0\x9F\x8F\xB0"; # uni 1F3E0..1F3F0
w1[234]="\xF0\x9F\x8F\xB4"; w2[234]="\xF0\x9F\x8F\xB4"; # uni 1F3F4
w1[235]="\xF0\x9F\x8F\xB8"; w2[235]="\xF0\x9F\x90\xBE"; # uni 1F3F8..1F43E
w1[236]="\xF0\x9F\x91\x80"; w2[236]="\xF0\x9F\x91\x80"; # uni 1F440
w1[237]="\xF0\x9F\x91\x82"; w2[237]="\xF0\x9F\x93\xBC"; # uni 1F442..1F4FC
w1[238]="\xF0\x9F\x93\xBF"; w2[238]="\xF0\x9F\x94\xBD"; # uni 1F4FF..1F53D
w1[239]="\xF0\x9F\x95\x8B"; w2[239]="\xF0\x9F\x95\x8E"; # uni 1F54B..1F54E
w1[240]="\xF0\x9F\x95\x90"; w2[240]="\xF0\x9F\x95\xA7"; # uni 1F550..1F567
w1[241]="\xF0\x9F\x95\xBA"; w2[241]="\xF0\x9F\x95\xBA"; # uni 1F57A
w1[242]="\xF0\x9F\x96\x95"; w2[242]="\xF0\x9F\x96\x96"; # uni 1F595..1F596
w1[243]="\xF0\x9F\x96\xA4"; w2[243]="\xF0\x9F\x96\xA4"; # uni 1F5A4
w1[244]="\xF0\x9F\x97\xBB"; w2[244]="\xF0\x9F\x99\x8F"; # uni 1F5FB..1F64F
w1[245]="\xF0\x9F\x9A\x80"; w2[245]="\xF0\x9F\x9B\x85"; # uni 1F680..1F6C5
w1[246]="\xF0\x9F\x9B\x8C"; w2[246]="\xF0\x9F\x9B\x8C"; # uni 1F6CC
w1[247]="\xF0\x9F\x9B\x90"; w2[247]="\xF0\x9F\x9B\x92"; # uni 1F6D0..1F6D2
w1[248]="\xF0\x9F\x9B\xAB"; w2[248]="\xF0\x9F\x9B\xAC"; # uni 1F6EB..1F6EC
w1[249]="\xF0\x9F\x9B\xB4"; w2[249]="\xF0\x9F\x9B\xB9"; # uni 1F6F4..1F6F9
w1[250]="\xF0\x9F\xA4\x90"; w2[250]="\xF0\x9F\xA4\xBE"; # uni 1F910..1F93E
w1[251]="\xF0\x9F\xA5\x80"; w2[251]="\xF0\x9F\xA5\xB0"; # uni 1F940..1F970
w1[252]="\xF0\x9F\xA5\xB3"; w2[252]="\xF0\x9F\xA5\xB6"; # uni 1F973..1F976
w1[253]="\xF0\x9F\xA5\xBA"; w2[253]="\xF0\x9F\xA5\xBA"; # uni 1F97A
w1[254]="\xF0\x9F\xA5\xBC"; w2[254]="\xF0\x9F\xA6\xA2"; # uni 1F97C..1F9A2
w1[255]="\xF0\x9F\xA6\xB0"; w2[255]="\xF0\x9F\xA6\xB9"; # uni 1F9B0..1F9B9
w1[256]="\xF0\x9F\xA7\x80"; w2[256]="\xF0\x9F\xA7\x82"; # uni 1F9C0..1F9C2
w1[257]="\xF0\x9F\xA7\x90"; w2[257]="\xF0\x9F\xA7\xBF"; # uni 1F9D0..1F9FF
w1[258]="\xF0\xA0\x80\x80"; w2[258]="\xF0\xAF\xBF\xBD"; # uni 20000..2FFFD
w1[259]="\xF0\xB0\x80\x80"; w2[259]="\xF0\xBF\xBF\xBD"; # uni 30000..3FFFD
w1[260]="\xF3\xA0\x84\x80"; w2[260]="\xF3\xA0\x87\xAF"; # uni E0100..E01EF
w1[261]="\xF3\xB0\x80\x80"; w2[261]="\xF3\xBF\xBF\xBD"; # uni F0000..FFFFD
w1[262]="\xF4\x80\x80\x80"; w2[262]="\xF4\x8F\xBF\xBD"; # uni 100000..10FFFD
'
else
EAW_F='
wlen=108;
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
fi

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
    for(i=1;i<=wlen;i++) {
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
      col=gensub(/^"([^\n]*)"$/,"\\1","g",col);
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
      for(i=1;i<=wlen;i++) {
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
        col=gensub(/^"([^\n]*)"$/,"\\1","g",col);
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
