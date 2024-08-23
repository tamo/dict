# Makefile: makefile for SKK Dictionaries.
#
# Maintainer: SKK Development Team <skk@ring.gr.jp>

COUNT	  = skkdic-count
CURL      = curl
DATE	  = date
DENO	  = deno
EMACS	  = emacs --batch --directory ./
EXPR	  = skkdic-expr
EXPR2	  = skkdic-expr2
GAWK	  = LC_ALL=C gawk
GREP	  = grep
GZIP	  = gzip -9
ICONV	  = iconv
MD5	  = md5
MV	  = mv --force
RM	  = /bin/rm -f
RUBY	  = ruby -I $(TOOLS_DIR)/filters
SED	  = sed
SORT	  = skkdic-sort
TAR	  = tar
TOUCH	  = touch
UNZIP	  = unzip -o

ZIPDIC_DIR  = ./zipcode

DIC2PDB = dic2pdb
DICCOMPACT = diccompact.rb
KANADIC2ROMADIC = kanadic2romadic
NKF = nkf
SKKDIC2KANADIC = skkdic2kanadic
TOOLS_DIR = ../tools

SRCS	  = SKK-JISYO.L SKK-JISYO.ML SKK-JISYO.M SKK-JISYO.S SKK-JISYO.JIS2 \
		SKK-JISYO.JIS3_4 SKK-JISYO.pubdic+ SKK-JISYO.wrong.annotated \
		SKK-JISYO.okinawa SKK-JISYO.geo SKK-JISYO.jinmei SKK-JISYO.law \
		SKK-JISYO.mazegaki SKK-JISYO.assoc SKK-JISYO.itaiji \
		SKK-JISYO.itaiji.JIS3_4 SKK-JISYO.china_taiwan \
		SKK-JISYO.propernoun SKK-JISYO.station SKK-JISYO.requested \
		SKK-JISYO.fullname SKK-JISYO.JIS2004 SKK-JISYO.lisp

# SKK-JISYO.noregist SKK-JISYO.hukugougo

# JSON から生成
EUC_SRCS = SKK-JISYO.assoc SKK-JISYO.china_taiwan SKK-JISYO.edict SKK-JISYO.geo SKK-JISYO.hukugougo SKK-JISYO.itaiji SKK-JISYO.jinmei SKK-JISYO.JIS2 SKK-JISYO.law SKK-JISYO.L SKK-JISYO.mazegaki SKK-JISYO.M SKK-JISYO.ML SKK-JISYO.okinawa SKK-JISYO.propernoun SKK-JISYO.pubdic+ SKK-JISYO.S SKK-JISYO.station
UTF_SRCS = SKK-JISYO.edict2 SKK-JISYO.emoji SKK-JISYO.fullname SKK-JISYO.pinyin
SKK-JISYO.%: json/SKK-JISYO.%.json meta/SKK-JISYO.%.yaml
	if [ "x$(filter $@,$(EUC_SRCS))" = "x$@" ]; then \
		$(DENO) run --allow-read --allow-write --allow-net script/json2txt.ts \
		-c EUC-JP -i json/$@.json -o $@ ; \
	elif [ "x$(filter $@,$(UTF_SRCS))" = "x$@" ]; then \
		$(DENO) run --allow-read --allow-write --allow-net script/json2txt.ts \
		-c UTF-8 -i json/$@.json -o $@ ; \
	fi

BIN_SRCS  = #PBinlineDB.pdb
ALL_SRCS  = $(SRCS) $(BIN_SRCS) $(EUC_SRCS) $(UTF_SRCS) SKK-JISYO.wrong SKK-JISYO.L.unannotated
# SKK-JISYO.L+ SKK-JISYO.L.taciturn SKK-JISYO.total

PYTHON    = python
SKK2CDB   = skk2cdb.py -f
CDB_SOURCE = ./SKK-JISYO.L
CDB_TARGET = ./`basename $(CDB_SOURCE)`.cdb

clean:
	$(RM) *.gz* *~ `find . -name '*~'` `find . -name '.*~'` `find . -name '.#*'` \
	*.unannotated SKK-JISYO.wrong PBinlineDB.pdb *.tmp *.u8 *.w PBinlineDB.dic *.taciturn \
	SKK-JISYO.L+ SKK-JISYO.total SKK-JISYO.total+zipcode SKK-JISYO.L.header SKK-JISYO.china_taiwan \
	emoji-list.txt $(EUC_SRCS) $(UTF_SRCS)

archive: gzip

unannotated: SKK-JISYO.L.unannotated SKK-JISYO.wrong SKK-JISYO.china_taiwan.unannotated

SKK-JISYO.L.unannotated: SKK-JISYO.L
	$(GAWK) -f $(TOOLS_DIR)/unannotation.awk SKK-JISYO.L > SKK-JISYO.L.unannotated

SKK-JISYO.wrong: SKK-JISYO.wrong.annotated
	$(GAWK) -f $(TOOLS_DIR)/unannotation.awk SKK-JISYO.wrong.annotated > SKK-JISYO.wrong

SKK-JISYO.china_taiwan: csv/china_taiwan.csv
	$(RUBY) $(TOOLS_DIR)/convert2skk/ctdicconv.rb csv/china_taiwan.csv > SKK-JISYO.tmp
	$(EXPR) SKK-JISYO.tmp | $(SORT) - > SKK-JISYO.1.tmp
	cat SKK-JISYO.china_taiwan.header SKK-JISYO.1.tmp > SKK-JISYO.china_taiwan
	$(RM) SKK-JISYO.tmp SKK-JISYO.1.tmp

SKK-JISYO.china_taiwan.unannotated: SKK-JISYO.china_taiwan csv/china_taiwan.csv
	$(GAWK) -f $(TOOLS_DIR)/unannotation.awk SKK-JISYO.china_taiwan > SKK-JISYO.china_taiwan.unannotated

wrong_check: SKK-JISYO.wrong
	for file in $(SRCS) ; do \
	  if [ $$file != "SKK-JISYO.wrong.annotated" ] ; then \
	    $(EXPR) $$file - SKK-JISYO.wrong > $$file.tmp ;\
	    $(EXPR) $$file - $$file.tmp > $$file.w ;\
	    $(RM) $$file.tmp ;\
	    $(COUNT) $$file.w | $(GREP) -v '0 candidate' | \
	      sed -e 's/\.w:/:/' -e 's/\([1-9]\)/\1 wrong/' ;\
	    if [ $$? != 0 ]; then \
	      $(RM) $$file.w ; \
	    fi ;\
	  fi ;\
	done

PBinlineDB.dic: clean SKK-JISYO.L.unannotated
	$(SKKDIC2KANADIC) SKK-JISYO.L.unannotated | $(KANADIC2ROMADIC) - | $(NKF) -s > PBinlineDB.dic

PBinlineDB_compact.pdb: PBinlineDB.dic
	 $(DICCOMPACT) PBinlineDB.dic | $(DIC2PDB) - PBinlineDB.pdb

PBinlineDB_full.pdb: PBinlineDB.dic
	$(DIC2PDB) PBinlineDB.dic PBinlineDB.pdb

PBinlineDB.pdb: PBinlineDB_full.pdb
	$(RM) PBinlineDB.dic

gzip: clean $(ALL_SRCS)
	for file in $(ALL_SRCS); do \
	  $(GZIP) -fc $$file >$$file.gz ;\
	  $(MD5) $$file.gz >$$file.gz.md5; \
	done
	$(TAR) cvpf SKK-JISYO.edict.tar SKK-JISYO.edict edict_doc.html
	$(GZIP) -f SKK-JISYO.edict.tar
	$(MD5) SKK-JISYO.edict.tar.gz > SKK-JISYO.edict.tar.gz.md5
	$(TAR) cvzpf zipcode.tar.gz --exclude-from=./skk.ex ./zipcode
	$(MD5) zipcode.tar.gz >zipcode.tar.gz.md5

SKK-JISYO.L+: SKK-JISYO.L SKK-JISYO.L.header
	$(RUBY) $(TOOLS_DIR)/filters/conjugation.rb -Cpox SKK-JISYO.notes > SKK-JISYO.tmp
	$(RUBY) $(TOOLS_DIR)/filters/asayaKe.rb -p SKK-JISYO.L >> SKK-JISYO.tmp
	$(RUBY) $(TOOLS_DIR)/filters/complete-numerative.rb -pU SKK-JISYO.L >> SKK-JISYO.tmp
	$(RUBY) $(TOOLS_DIR)/filters/abbrev-convert.rb -K -s 2 SKK-JISYO.L >> SKK-JISYO.tmp
	$(RUBY) $(TOOLS_DIR)/filters/abbrev-convert.rb -w -s 2 SKK-JISYO.L >> SKK-JISYO.tmp
	$(EXPR2) SKK-JISYO.L + SKK-JISYO.tmp | cat SKK-JISYO.L.header - > SKK-JISYO.L+
	$(RM) SKK-JISYO.tmp SKK-JISYO.addition

SKK-JISYO.total: SKK-JISYO.L.u8 SKK-JISYO.geo.u8 SKK-JISYO.station.u8 SKK-JISYO.jinmei.u8 SKK-JISYO.propernoun.u8 SKK-JISYO.fullname SKK-JISYO.law.u8 SKK-JISYO.okinawa.u8 SKK-JISYO.hukugougo.u8 SKK-JISYO.assoc.u8 SKK-JISYO.notes SKK-JISYO.L.header.u8
	$(RUBY) $(TOOLS_DIR)/filters/conjugation.rb -Cpox SKK-JISYO.notes > SKK-JISYO.tmp
	$(RUBY) $(TOOLS_DIR)/filters/asayaKe.rb -p SKK-JISYO.L >> SKK-JISYO.tmp
	$(RUBY) $(TOOLS_DIR)/filters/complete-numerative.rb -pU SKK-JISYO.L >> SKK-JISYO.tmp
	$(RUBY) $(TOOLS_DIR)/filters/abbrev-convert.rb -K -s 2 SKK-JISYO.L >> SKK-JISYO.tmp
	$(RUBY) $(TOOLS_DIR)/filters/abbrev-convert.rb -w -s 2 SKK-JISYO.L >> SKK-JISYO.tmp
	$(ICONV) -f euc-jp -t utf-8 SKK-JISYO.tmp > SKK-JISYO.tmp.u8
	# order is very important here
	$(EXPR2) SKK-JISYO.geo.u8 + SKK-JISYO.station.u8 + SKK-JISYO.jinmei.u8 + SKK-JISYO.propernoun.u8 + SKK-JISYO.fullname + SKK-JISYO.tmp.u8 + SKK-JISYO.law.u8 + SKK-JISYO.okinawa.u8 + SKK-JISYO.hukugougo.u8 + SKK-JISYO.assoc.u8 - SKK-JISYO.L.u8 > SKK-JISYO.addition
	# why eliminating SKK-JISYO.L once? -- to not add too noisy
	# annotations from SKK-JISYO.jinmei and so on.
	$(EXPR2) SKK-JISYO.L.u8 + SKK-JISYO.addition | cat SKK-JISYO.L.header.u8 - > SKK-JISYO.total
	$(RM) SKK-JISYO.tmp SKK-JISYO.addition

SKK-JISYO.total+zipcode: SKK-JISYO.total $(ZIPDIC_DIR)/SKK-JISYO.zipcode $(ZIPDIC_DIR)/SKK-JISYO.office.zipcode SKK-JISYO.L.header.u8
	$(EXPR2) SKK-JISYO.total + $(ZIPDIC_DIR)/SKK-JISYO.zipcode + $(ZIPDIC_DIR)/SKK-JISYO.office.zipcode | cat SKK-JISYO.L.header.u8 - > SKK-JISYO.total+zipcode

SKK-JISYO.L.taciturn: SKK-JISYO.L SKK-JISYO.L.header
	$(RUBY) $(TOOLS_DIR)/filters/annotation-filter.rb -d SKK-JISYO.L | $(EXPR2) | cat SKK-JISYO.L.header - > SKK-JISYO.L.taciturn

SKK-JISYO.L+.taciturn: SKK-JISYO.L+ SKK-JISYO.L.header
	$(RUBY) $(TOOLS_DIR)/filters/annotation-filter.rb -d SKK-JISYO.L+ | $(EXPR2) | cat SKK-JISYO.L.header - > SKK-JISYO.L+.taciturn

SKK-JISYO.total.taciturn: SKK-JISYO.total SKK-JISYO.L.header.u8
	$(RUBY) script/annotation-filter.rb -8 -d SKK-JISYO.total | $(EXPR2) | cat SKK-JISYO.L.header.u8 - > SKK-JISYO.total.taciturn

SKK-JISYO.total+zipcode.taciturn: SKK-JISYO.total+zipcode SKK-JISYO.L.header.u8
	$(RUBY) script/annotation-filter.rb -8 -d SKK-JISYO.total+zipcode | $(EXPR2) | cat SKK-JISYO.L.header.u8 - > SKK-JISYO.total+zipcode.taciturn

SKK-JISYO.L+.unannotated: SKK-JISYO.L+
	$(GAWK) -f $(TOOLS_DIR)/unannotation.awk SKK-JISYO.L+ > SKK-JISYO.L+.unannotated

SKK-JISYO.total.unannotated: SKK-JISYO.total
	$(GAWK) -f $(TOOLS_DIR)/unannotation.awk SKK-JISYO.total > SKK-JISYO.total.unannotated

SKK-JISYO.total+zipcode.unannotated: SKK-JISYO.total+zipcode
	$(GAWK) -f $(TOOLS_DIR)/unannotation.awk SKK-JISYO.total+zipcode > SKK-JISYO.total+zipcode.unannotated

SKK-JISYO.L.header: SKK-JISYO.L
	echo ';; (This dictionary was automatically generated from SKK dictionaries)' > SKK-JISYO.L.header
	$(SED) -n '/^;; okuri-ari entries./q;p' SKK-JISYO.L >> SKK-JISYO.L.header

SKK-JISYO.L.header.u8: SKK-JISYO.L.header
	$(ICONV) -f euc-jp -t utf-8 SKK-JISYO.L.header > SKK-JISYO.L.header.u8
	$(SED) -i "2s/coding: euc-jp /coding: utf-8 /" SKK-JISYO.L.header.u8
%.u8: %
	$(ICONV) -f euc-jp -t utf-8 $< > $@


unannotated-all: unannotated SKK-JISYO.L+.unannotated SKK-JISYO.total.unannotated SKK-JISYO.total+zipcode.unannotated

taciturn-all: SKK-JISYO.L.taciturn SKK-JISYO.L+.taciturn SKK-JISYO.total.taciturn SKK-JISYO.total+zipcode.taciturn

annotated-all: SKK-JISYO.L+ SKK-JISYO.total SKK-JISYO.total+zipcode

all: $(EUC_SRCS) $(UTF_SRCS) annotated-all unannotated-all taciturn-all

cdb:
	$(PYTHON) $(TOOLS_DIR)/$(SKK2CDB) $(CDB_TARGET) $(CDB_SOURCE)


# Unicode emoji
# https://cldr.unicode.org/index/downloads/latest

CLDR_VER = 45
CLDR_COMMON_VER = 45.0

SKK-JISYO.emoji: SKK-JISYO.emoji.en SKK-JISYO.emoji.ja SKK-JISYO.emoji.kana unicode-license.txt
	$(EXPR2) SKK-JISYO.emoji.en + SKK-JISYO.emoji.ja + SKK-JISYO.emoji.kana \
	  > SKK-JISYO.emoji.tmp
	echo '-*- mode: fundamental; coding: utf-8 -*-' | cat - unicode-license.txt | $(SED) "s/^/;; /g" | cat - SKK-JISYO.emoji.tmp > SKK-JISYO.emoji
	$(RM) SKK-JISYO.emoji.en SKK-JISYO.emoji.ja en.xml ja.xml
	$(RM) SKK-JISYO.emoji.tmp SKK-JISYO.emoji.kana

SKK-JISYO.emoji.en: cldr-common.zip
	test -f en.xml || $(UNZIP) -p cldr-common.zip "*common/annotations/en.xml" > en.xml
	$(EMACS) --load emoji.el --funcall en > SKK-JISYO.emoji.en

SKK-JISYO.emoji.ja: cldr-common.zip
	test -f ja.xml || $(UNZIP) -p cldr-common.zip "*common/annotations/ja.xml" > ja.xml
	$(EMACS) --load emoji.el --funcall ja > SKK-JISYO.emoji.ja

SKK-JISYO.emoji.kana: SKK-JISYO.emoji.kanji SKK-JISYO.L.unannotated
	$(EMACS) --load emoji.el --funcall kanji-to-kana > SKK-JISYO.emoji.kana
	$(RM) SKK-JISYO.emoji.kanji

SKK-JISYO.emoji.kanji: cldr-common.zip
	test -f ja.xml || $(UNZIP) -p cldr-common.zip "*common/annotations/ja.xml" > ja.xml
	$(EMACS) --load emoji.el --funcall kanjionly | $(EXPR2) > SKK-JISYO.emoji.kanji

unicode-license.txt: cldr-common.zip
	test -f unicode-license.txt || $(UNZIP) -p cldr-common.zip "LICENSE" > unicode-license.txt

cldr-common.zip:
	test -f cldr-common.zip || $(CURL) -o cldr-common.zip https://unicode.org/Public/cldr/$(CLDR_VER)/cldr-common-$(CLDR_COMMON_VER).zip

# http://www.edrdg.org/jmdict/edict.html
#   ELECTRONIC DICTIONARY RESEARCH AND DEVELOPMENT GROUP GENERAL DICTIONARY LICENCE STATEMENT
#   http://www.edrdg.org/edrdg/licence.html
# http://ftp.edrdg.org/pub/Nihongo/00INDEX.html
#   After nearly 30 years of operation the Monash ftp server has been closed down.

SKK-JISYO.edict2: edict2u
	$(EMACS) --load $(TOOLS_DIR)/convert2skk/edict2toskk.el --funcall main | $(EXPR2) > SKK-JISYO.edict2.tmp
	$(EMACS) --load $(TOOLS_DIR)/convert2skk/edict2toskk.el --funcall after
	$(MV) SKK-JISYO.edict2.tmp SKK-JISYO.edict2
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

# json/%.json が % に依存すると循環するので注意
EUC_JSON = $(patsubst %,json/%.json,$(EUC_SRCS))
UTF_JSON = $(patsubst %,json/%.json,$(UTF_SRCS))
json: $(EUC_JSON) $(UTF_JSON)
json/%.json:
	TXT=$(patsubst json/%.json,%,$@) ; \
	if [ "x$(filter $@,$(EUC_JSON))" = "x$@" ]; then \
		$(DENO) run --allow-read --allow-write --allow-net script/txt2json.ts \
		-c EUC-JP -i $${TXT} -m meta/$${TXT}.yaml -o $@ -s schema/jisyo.schema.v0.1.0.json ; \
	elif [ "x$(filter $@,$(UTF_JSON))" = "x$@" ]; then \
		$(DENO) run --allow-read --allow-write --allow-net script/txt2json.ts \
		-c UTF-8 -i $${TXT} -m meta/$${TXT}.yaml -o $@ -s schema/jisyo.schema.v0.1.0.json ; \
	fi
# end of Makefile.
