# make-kit.mk for bashics
make-kit.mk: ;
#  This makefile is included by the root shellkit Makefile
#  It defines values that are kit-specific.
#  You should edit it and keep it source-controlled.

# The shellkit/ tooling naturally evolves out from under the dependent kits.  ShellkitSetupVers allows
# detecting the need for refresh of templates/* derived files.  To bump the root version, 
# zap all templates/* containing 'ShellkitTemplateVers' constants and changes to the corresponding dependent kits
# Note that within templates/* there may be diverse versions in upstream shellkit, they don't all have to match,
# but the derived copies should be sync'ed with upstream as needed.
ShellkitTemplateVers=3

# TODO: update kit_depends to include anything which
#   might require the kit version to change as seen
#   by the user -- i.e. the files that get installed,
#   or anything which generates those files.
kit_depends := \
    bin/bashics.bashrc \
    bin/bashics.sh

CompleteAliasRoot=$(ShellkitWorkspace)/complete-alias

.PHONY: publish publish-draft

.PHONY: prepare-complete-alias
prepare-complete-alias:
	[[ -d $(CompleteAliasRoot) ]] && {
		(
			cd $(CompleteAliasRoot) && git pull
		)
	} || {
		(
			cd $(ShellkitWorkspace)  \
				&& git clone https://github.com/sanekits/complete-alias ;
		)
	}

	# Extract the files we care about:
	for ff in complete_alias completion_loader; do \
		cp $(CompleteAliasRoot)/$${ff} bin/$${ff}; \
	done

tree-setup: prepare-complete-alias


publish-common: conformity-check

publish: pre-publish publish-common release-upload release-list
	cat tmp/draft-url
	@echo ">>>> publish complete OK. (FINAL)  <<<"

publish-draft: pre-publish publish-common release-draft-upload release-list
	cat tmp/draft-url
	@echo ">>>> publish complete OK. (DRAFT - you must manually publish it from github release page)  <<<"

.docker-lab-postcreate: .footest
.footest:
	@ # TODO: add bashics setup or launch menu?  This runs in entrypoint
