# Makefile for foo
SHELL=/bin/bash
.ONESHELL:
.SUFFIXES:
.SHELLFLAGS = -uec
MAKEFLAGS += --no-builtin-rules --no-print-directory

#	PS4=$(PS4x)  # Copy this into recipe to enable smart PS4 
#PS4x='$$( _0=$$?;_1="$@"; exec 2>/dev/null; echo "$(realpath $(lastword $(MAKEFILE_LIST)))|$${_1:0:12}+$${LINENO} ^$$_0 $${FUNCNAME[0]:-?}()=>" ) '  # reference
#PS4x='$$( _0=$$?;_1="$(notdir $@)";_2=$(realpath $(lastword $(MAKEFILE_LIST))); exec 2>/dev/null; echo "$${_2}|$${_1}@+$${LINENO} ^$$_0 $${FUNCNAME[0]:-?}()=>" ) ' # reference NEW
absdir := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))


#	PS4=$(PS4x)  # <-- Copy/uncomment this in recipe to enable smart PS4 
PS4x='$$( _0=$$?;_1="$(notdir $@)";_2="$(realpath $(lastword $(MAKEFILE_LIST)))"; exec 2>/dev/null; echo "$${_2}|$${_1}@+$${LINENO} ^$$_0 $${FUNCNAME[0]:-?}()=>" ) ' # reference NEW
#===== TEST: ==============
#	PS4=$(PS4x)  # <-- Copy/uncomment this in recipe to enable smart PS4 
PS4x='$$( _0=$$?;_1="$(notdir $@)";_2="$(realpath $(lastword $(MAKEFILE_LIST)))"; exec 2>/dev/null; echo "$${_2}|$${_1}@+$${LINENO} ^$$_0 $${FUNCNAME[0]:-?}()=>" ) '
#--------------------------

$(absdir)a_really_long.txt:
	@# do foo
	PS4=$(PS4x)
	echo ------
	echo "[PS4=$$PS4]"
	echo ------
	set -x
	foo_in() {
		echo "we're in a function now: $*"
	}
	_x="$@"
	echo "long target: $$_x"
	echo "short target: $${_x:(-12)}"
	for vv in {a..c}; do
		echo "$$vv"
		set +e; false;
		foo_in "$$vv"
		set -e
	done
