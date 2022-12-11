# make-kit.mk for bashics
#  This makefile is included by the root shellkit Makefile
#  It defines values that are kit-specific.
#  You should edit it and keep it source-controlled.

# TODO: update kit_depends to include anything which
#   might require the kit version to change as seen
#   by the user -- i.e. the files that get installed,
#   or anything which generates those files.
kit_depends := \
    bin/bashics.bashrc \
    bin/bashics.sh

CompleteAliasRoot=$(ShellkitWorkspace)/complete-alias

.PHONY: publish

.PHONY: prepare-complete-alias
prepare-complete-alias:
	[[ -d $(CompleteAliasRoot) ]]  \
		&& { cd $(CompleteAliasRoot) && git pull ; } \
	|| {  \
			cd $(ShellkitWorkspace) \
				&& git clone https://github.com/sanekits/complete-alias ; \
		} \

	# Extract the files we care about:
	for ff in complete_alias completion_loader; do \
		cp $(CompleteAliasRoot)/$${ff} bin/$${ff}; \
	done

tree-setup: prepare-complete-alias

publish-common: conformity-check

publish: pre-publish publish-common release-draft-upload release-list


	@echo ">>>> publish complete OK.  <<<"
	@echo ">>>> Manually publish the release from this URL when satisfied, <<<<"
	@echo ">>>> and then change ./version to avoid accidental confusion. <<<<"
	cat tmp/draft-url
