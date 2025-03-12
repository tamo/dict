# Makefile: makefile for SKK Dictionaries.
#
# Maintainer: SKK Development Team <skk@ring.gr.jp>

CURL      = curl
DATE	  = date
DENO	  = deno
EMACS	  = emacs --batch --directory ./
GAWK	  = LC_ALL=C gawk
GREP	  = grep
GZIP	  = gzip -9
ICONV	  = iconv
MD5	  = md5
MV	  = mv -f
RM	  = /bin/rm -f
RUBY	  = ruby -I ./filters
SED	  = sed
TAR	  = tar
TOUCH	  = touch
UNZIP	  = unzip -o

ZIPDIC_DIR  = ./zipcode

TOOLS_DIR = ../tools
COUNT	  = PATH="$(PATH):$(TOOLS_DIR)" skkdic-count
EXPR2	  = PATH="$(PATH):$(TOOLS_DIR)" skkdic-expr2
SORT	  = PATH="$(PATH):$(TOOLS_DIR)" skkdic-sort


SRCS = \
	SKK-JISYO.wrong \
	SKK-JISYO.requested \
	SKK-JISYO.lisp \
	# SKK-JISYO.noregist

TARGETS = \
	SKK-JISYO.JIS2 \
	SKK-JISYO.L \
	SKK-JISYO.S \
	SKK-JISYO.assoc \
	SKK-JISYO.edict2 \
	SKK-JISYO.emoji \
	SKK-JISYO.fullname \
	SKK-JISYO.geo \
	SKK-JISYO.hukugougo \
	SKK-JISYO.itaiji \
	SKK-JISYO.jinmei \
	SKK-JISYO.law \
	SKK-JISYO.okinawa \
	SKK-JISYO.propernoun \
	SKK-JISYO.station \
	# SKK-JISYO.itaiji.UTF-8

SKK-JISYO.%: json/SKK-JISYO.%.json meta/SKK-JISYO.%.yaml
	$(DENO) run --allow-read --allow-write --allow-net script/json2txt.ts \
	-c UTF-8 -i json/$@.json -o $@

ALL_SRCS  = $(SRCS) $(TARGETS) SKK-JISYO.L.unannotated SKK-JISYO.L+
# SKK-JISYO.L.taciturn SKK-JISYO.total

clean:
	$(RM) *.gz* *~ `find . -name '*~'` `find . -name '.*~'` `find . -name '.#*'` \
	*.unannotated *.tmp *.w *.taciturn \
	SKK-JISYO.L+ SKK-JISYO.total SKK-JISYO.total+zipcode SKK-JISYO.L.header \
	SKK-JISYO.emoji.en SKK-JISYO.emoji.ja en.xml ja.xml \
	itaiji_list.* variant0213.* jisx0213misc.zip \
	emoji-list.txt $(TARGETS)

archive: gzip

unannotated: SKK-JISYO.L.unannotated

SKK-JISYO.L.unannotated: SKK-JISYO.L
	$(GAWK) -f $(TOOLS_DIR)/unannotation.awk SKK-JISYO.L > SKK-JISYO.L.unannotated

wrong_check: SKK-JISYO.wrong
	for file in $(TARGETS) ; do \
	    $(EXPR2) $$file - SKK-JISYO.wrong > $$file.tmp ;\
	    $(EXPR2) $$file - $$file.tmp > $$file.w ;\
	    $(RM) $$file.tmp ;\
	    $(COUNT) $$file.w | $(GREP) -v ': 0 candidate' | \
	      $(SED) -e 's/\.w:/:/' -e 's/: \([0-9]+\) /\1 wrong /' ;\
	    if [ ! -s $$file.w ]; then \
	      $(RM) $$file.w ; \
	    fi ;\
	done


gzip: clean $(ALL_SRCS)
	for file in $(ALL_SRCS); do \
	  $(GZIP) -fc $$file >$$file.gz ;\
	  $(MD5) $$file.gz >$$file.gz.md5; \
	done
	$(TAR) cvzpf zipcode.tar.gz --exclude-from=./skk.ex ./zipcode
	$(MD5) zipcode.tar.gz >zipcode.tar.gz.md5

SKK-JISYO.L+: SKK-JISYO.L SKK-JISYO.L.header
	$(RUBY) ./filters/conjugation.rb         -Cpox8   SKK-JISYO.L >  SKK-JISYO.tmp
	$(RUBY) ./filters/asayaKe.rb             -p8      SKK-JISYO.L >> SKK-JISYO.tmp
	$(RUBY) ./filters/complete-numerative.rb -pU8     SKK-JISYO.L >> SKK-JISYO.tmp
	$(RUBY) ./filters/abbrev-convert.rb      -K8 -s 2 SKK-JISYO.L >> SKK-JISYO.tmp
	$(RUBY) ./filters/abbrev-convert.rb      -w8 -s 2 SKK-JISYO.L >> SKK-JISYO.tmp
	$(EXPR2) SKK-JISYO.L + SKK-JISYO.tmp | cat SKK-JISYO.L.header - > SKK-JISYO.L+
	$(RM) SKK-JISYO.tmp

SKK-JISYO.total: SKK-JISYO.L SKK-JISYO.geo SKK-JISYO.station SKK-JISYO.jinmei SKK-JISYO.propernoun SKK-JISYO.fullname SKK-JISYO.law SKK-JISYO.okinawa SKK-JISYO.hukugougo SKK-JISYO.assoc SKK-JISYO.L.header
	$(RUBY) ./filters/conjugation.rb         -Cpox8   SKK-JISYO.L >  SKK-JISYO.tmp
	$(RUBY) ./filters/asayaKe.rb             -p8      SKK-JISYO.L >> SKK-JISYO.tmp
	$(RUBY) ./filters/complete-numerative.rb -pU8     SKK-JISYO.L >> SKK-JISYO.tmp
	$(RUBY) ./filters/abbrev-convert.rb      -K8 -s 2 SKK-JISYO.L >> SKK-JISYO.tmp
	$(RUBY) ./filters/abbrev-convert.rb      -w8 -s 2 SKK-JISYO.L >> SKK-JISYO.tmp
	# order is very important here
	$(EXPR2) SKK-JISYO.geo + SKK-JISYO.station + SKK-JISYO.jinmei + SKK-JISYO.propernoun + SKK-JISYO.fullname + SKK-JISYO.tmp + SKK-JISYO.law + SKK-JISYO.okinawa + SKK-JISYO.hukugougo + SKK-JISYO.assoc - SKK-JISYO.L > SKK-JISYO.addition
	# why eliminating SKK-JISYO.L once? -- to not add too noisy
	# annotations from SKK-JISYO.jinmei and so on.
	$(EXPR2) SKK-JISYO.L + SKK-JISYO.addition | cat SKK-JISYO.L.header - > SKK-JISYO.total
	$(RM) SKK-JISYO.tmp SKK-JISYO.addition

SKK-JISYO.total+zipcode: SKK-JISYO.total $(ZIPDIC_DIR)/SKK-JISYO.zipcode $(ZIPDIC_DIR)/SKK-JISYO.office.zipcode SKK-JISYO.L.header
	$(EXPR2) SKK-JISYO.total + $(ZIPDIC_DIR)/SKK-JISYO.zipcode + $(ZIPDIC_DIR)/SKK-JISYO.office.zipcode | cat SKK-JISYO.L.header - > SKK-JISYO.total+zipcode

SKK-JISYO.L.taciturn: SKK-JISYO.L SKK-JISYO.L.header
	$(RUBY) ./filters/annotation-filter.rb -d8 SKK-JISYO.L | $(EXPR2) | cat SKK-JISYO.L.header - > SKK-JISYO.L.taciturn

SKK-JISYO.L+.taciturn: SKK-JISYO.L+ SKK-JISYO.L.header
	$(RUBY) ./filters/annotation-filter.rb -d8 SKK-JISYO.L+ | $(EXPR2) | cat SKK-JISYO.L.header - > SKK-JISYO.L+.taciturn

SKK-JISYO.total.taciturn: SKK-JISYO.total SKK-JISYO.L.header
	$(RUBY) script/annotation-filter.rb -d8 SKK-JISYO.total | $(EXPR2) | cat SKK-JISYO.L.header - > SKK-JISYO.total.taciturn

SKK-JISYO.total+zipcode.taciturn: SKK-JISYO.total+zipcode SKK-JISYO.L.header
	$(RUBY) script/annotation-filter.rb -d8 SKK-JISYO.total+zipcode | $(EXPR2) | cat SKK-JISYO.L.header - > SKK-JISYO.total+zipcode.taciturn

SKK-JISYO.L+.unannotated: SKK-JISYO.L+
	$(GAWK) -f $(TOOLS_DIR)/unannotation.awk SKK-JISYO.L+ > SKK-JISYO.L+.unannotated

SKK-JISYO.total.unannotated: SKK-JISYO.total
	$(GAWK) -f $(TOOLS_DIR)/unannotation.awk SKK-JISYO.total > SKK-JISYO.total.unannotated

SKK-JISYO.total+zipcode.unannotated: SKK-JISYO.total+zipcode
	$(GAWK) -f $(TOOLS_DIR)/unannotation.awk SKK-JISYO.total+zipcode > SKK-JISYO.total+zipcode.unannotated

SKK-JISYO.L.header: SKK-JISYO.L
	echo ';; (This dictionary was automatically generated from SKK dictionaries)' > SKK-JISYO.L.header
	$(SED) -n '/^;; okuri-ari entries./q;p' SKK-JISYO.L >> SKK-JISYO.L.header


unannotated-all: unannotated SKK-JISYO.L+.unannotated SKK-JISYO.total.unannotated SKK-JISYO.total+zipcode.unannotated

taciturn-all: SKK-JISYO.L.taciturn SKK-JISYO.L+.taciturn SKK-JISYO.total.taciturn SKK-JISYO.total+zipcode.taciturn

annotated-all: SKK-JISYO.L+ SKK-JISYO.total SKK-JISYO.total+zipcode

all: $(TARGETS) annotated-all unannotated-all taciturn-all


# Unicode emoji
# https://cldr.unicode.org/index/downloads/latest

CLDR_VER = 46
CLDR_COMMON_VER = 46.0
CLDR_URL = https://unicode.org/Public/cldr/$(CLDR_VER)/cldr-common-$(CLDR_COMMON_VER).zip

SKK-JISYO.emoji: SKK-JISYO.emoji.en SKK-JISYO.emoji.ja unicode-license.txt
	$(EXPR2) SKK-JISYO.emoji.en + SKK-JISYO.emoji.ja \
	  > SKK-JISYO.emoji.tmp
	echo '-*- mode: fundamental; coding: utf-8 -*-' \
	  | cat - unicode-license.txt \
	  | $(SED) "s/^/;; /g" \
	  | cat - SKK-JISYO.emoji.tmp \
	  > SKK-JISYO.emoji

SKK-JISYO.emoji.en: en.xml
	$(DENO) --allow-read --allow-write script/emoji.ts -x en.xml \
	  -o SKK-JISYO.emoji.en

SKK-JISYO.emoji.ja: ja.xml SKK-JISYO.emoji.predef
	$(DENO) --allow-read --allow-write script/emoji.ts -x ja.xml \
	  -o SKK-JISYO.emoji.ja -p SKK-JISYO.emoji.predef

SKK-JISYO.emoji.predef: ja.xml
	$(MAKE) SKK-JISYO.L+
	touch SKK-JISYO.emoji.predef
	$(DENO) --allow-read --allow-write script/emoji.ts -x ja.xml \
	  -o SKK-JISYO.emoji.predef -p SKK-JISYO.emoji.predef \
	  -i SKK-JISYO.L+ -c EUC-JP

en.xml: cldr-common.zip
	$(UNZIP) -p cldr-common.zip "*common/annotations/en.xml" > en.xml

ja.xml: cldr-common.zip
	$(UNZIP) -p cldr-common.zip "*common/annotations/ja.xml" > ja.xml

unicode-license.txt: cldr-common.zip
	$(UNZIP) -p cldr-common.zip "LICENSE" > unicode-license.txt

cldr-common.zip:
	$(CURL) -o cldr-common.zip $(CLDR_URL)

# http://www.edrdg.org/jmdict/edict.html
#   ELECTRONIC DICTIONARY RESEARCH AND DEVELOPMENT GROUP GENERAL DICTIONARY LICENCE STATEMENT
#   http://www.edrdg.org/edrdg/licence.html
# http://ftp.edrdg.org/pub/Nihongo/00INDEX.html
#   After nearly 30 years of operation the Monash ftp server has been closed down.

SKK-JISYO.edict2: edict2u
	$(DENO) --allow-read --allow-write script/edict2.ts -i edict2u -o SKK-JISYO.edict2
	$(RM) json/SKK-JISYO.edict2.json
	$(MAKE) json/SKK-JISYO.edict2.json
	$(DENO) --allow-read --allow-write script/json2txt.ts \
		-c UTF-8 -i json/SKK-JISYO.edict2.json -o SKK-JISYO.edict2
	$(GZIP) -fc SKK-JISYO.edict2 > SKK-JISYO.edict2.gz
	$(MD5) SKK-JISYO.edict2.gz > SKK-JISYO.edict2.gz.md5

edict2u:
	$(CURL) -o edict2u.gz http://ftp.edrdg.org/pub/Nihongo/edict2u.gz
	$(GZIP) --force --decompress edict2u.gz


# Unicode Ideographic Variation Database (IVD)
IVD_VER = 2022-09-13

SKK-JISYO.ivd: IVD_Sequences.txt IVD_Collections.txt
	$(EMACS) --load ivd.el --funcall make-ivd-jisyo | $(EXPR2) > SKK-JISYO.ivd.tmp
	echo '-*- mode: fundamental; coding: utf-8 -*-' | cat - unicode-license.txt | $(SED) "s/^/;; /g" | cat - SKK-JISYO.ivd.tmp > SKK-JISYO.ivd
	$(RM) SKK-JISYO.ivd.tmp

IVD_Sequences.txt:
	test -f IVD_Sequences.txt || $(CURL) -o IVD_Sequences.txt https://unicode.org/ivd/data/$(IVD_VER)/IVD_Sequences.txt

IVD_Collections.txt:
	test -f IVD_Collections.txt || $(CURL) -o IVD_Collections.txt https://unicode.org/ivd/data/$(IVD_VER)/IVD_Collections.txt


SKK-JISYO.itaiji: SKK-JISYO.itaiji.original itaiji_list.skk itaiji_list.html variant0213.txt.skk jisx0213misc.zip
	$(EXPR2) SKK-JISYO.itaiji.original + itaiji_list.skk + variant0213.txt.skk > SKK-JISYO.itaiji.UTF-8
	$(RM)   json/SKK-JISYO.itaiji.UTF-8.json
	$(MAKE) json/SKK-JISYO.itaiji.UTF-8.json
	$(MAKE)      SKK-JISYO.itaiji.UTF-8
	$(MV)        SKK-JISYO.itaiji.UTF-8 SKK-JISYO.itaiji

# 史料編纂所データベース異体字同定一覧（東京大学史料編纂所編）
SHIPS_URL = https://wwwap.hi.u-tokyo.ac.jp/ships/itaiji_list.jsp

itaiji_list.skk: itaiji_list.html
	./script/itaiji_list.sh < itaiji_list.html > itaiji_list.skk

itaiji_list.html:
	$(CURL) -o itaiji_list.html $(SHIPS_URL)

# JISX0213 InfoCenter
JISX_URL = https://www.jca.apc.org/~earthian/aozora/0213/misc0c23.zip

variant0213.txt.skk: variant0213.txt
	$(ICONV) -f SHIFT_JISX0213 -t UTF-8 variant0213.txt | $(SED) -ne 's/),/\//g;s/^[0-9-]*,(\(.\)/\1 /;s/[0-9-]*,(//gp' > variant0213.txt.skk

variant0213.txt: jisx0213misc.zip
	$(UNZIP) -p jisx0213misc.zip "variant0213.txt" > variant0213.txt

jisx0213misc.zip:
	$(CURL) -o jisx0213misc.zip $(JISX_URL)

# json/%.json が % に依存すると循環するので注意
JSONS = $(patsubst %,json/%.json,$(TARGETS))
json: $(JSONS)
json/%.json:
	TXT=$(patsubst json/%.json,%,$@) ; \
	$(DENO) run --allow-read --allow-write --allow-net script/txt2json.ts \
	-c UTF-8 -i $${TXT} -m meta/$${TXT}.yaml -o $@ -s schema/jisyo.schema.v0.1.0.json
# end of Makefile.
