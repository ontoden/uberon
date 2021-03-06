OBO=http://purl.obolibrary.org/obo
CATALOG=catalog-v001.xml
DC = http://purl.org/dc/elements/1.1
DATE = `date +%Y-%m-%d`
RELEASE = $(OBO)/uberon/releases/`date +%Y-%m-%d`

# ----------------------------------------
# ----------------------------------------
# NEW, POST-JUNE-2013
# ----------------------------------------
# ----------------------------------------

UCAT = --use-catalog

# SEED ONTOLOGY - use to make import modules
#
# for now we combine all cell and gross anatomy into one edit file; TODO - ext
# (syn for core.owl)
uberon_edit_safe.obo: uberon_edit.obo 
	egrep -v 'spatially_disjoint_from.*pending' $< > $@
uberon_edit.owl: uberon_edit_safe.obo 
	owltools $(UCAT) $< --merge-support-ontologies --expand-macros -o -f functional $@
### TODO - restore --expand-macros
###	owltools $(UCAT) $< --merge-support-ontologies --expand-macros -o -f functional $@

# todo - rename this
core.owl:
	ln -s $@ uberon_edit.owl


pe:
	mkdir pe

# note: developers may want to do this via a symlink
#pe/phenoscape-ext.owl: pe
#	wget http://purl.obolibrary.org/obo/uberon/phenoscape-ext.owl -O $@

# this is primarily used for seeding
phenoscape-ext-noimports.owl: pe/phenoscape-ext.owl
	owltools $(UCAT) $< --remove-imports-declarations -o -f functional $@


corecheck.owl: uberon_edit.obo 
	owltools $(UCAT) $< external-disjoints.owl --merge-support-ontologies --expand-macros --assert-inferred-subclass-axioms --useIsInferred -o -f functional $@


# ----------------------------------------
# IMPORTS
# ----------------------------------------

# seed.owl is never released - it is used to seed module extraction
seed.owl: phenoscape-ext-noimports.owl uberon_edit.owl cl-core.obo
	owltools $(UCAT) uberon_edit.owl $< cl-core.obo --merge-support-ontologies -o -f functional $@
# this is used for xrefs for bridge files
seed.obo: seed.owl
	owltools $(UCAT) $< -o -f obo $@

# todo - change to phenoscape-ext
#EDITSRC = uberon_edit.owl
EDITSRC = seed.owl
IMP = $(OBO)/uberon

pato.owl: uberon.owl
	owltools $(OBO)/$@ --extract-mingraph --make-subset-by-properties BFO:0000050 // --set-ontology-id $(OBO)/$@ -o $@
pato_import.owl: pato.owl $(EDITSRC) 
	owltools $(UCAT) --map-ontology-iri $(IMP)/$@ $< $(EDITSRC) --extract-module -s $(OBO)/$< -c --extract-mingraph --set-ontology-id -v $(RELEASE)/$@ $(IMP)/$@ -o $@

# TODO - logical definitions go->ubr,cl
go.owl: uberon.owl
	owltools $(OBO)/$@ --extract-mingraph --set-ontology-id $(OBO)/$@ -o $@
go_import.owl: go.owl $(EDITSRC) 
	owltools $(UCAT) --map-ontology-iri $(IMP)/$@ $< $(EDITSRC) --extract-module -s $(OBO)/$< -c --extract-mingraph --set-ontology-id  -v $(RELEASE)/$@ $(IMP)/$@ -o $@

envo.owl: uberon.owl
	owltools $(OBO)/$@ --extract-mingraph --set-ontology-id $(OBO)/$@ -o $@
envo_import.owl: envo.owl $(EDITSRC) 
	owltools $(UCAT) --map-ontology-iri $(IMP)/$@ $< $(EDITSRC) --extract-module -s $(OBO)/$< -c --make-subset-by-properties  --extract-mingraph --set-ontology-id  -v $(RELEASE)/$@ $(IMP)/$@ -o $@

nbo.owl: uberon.owl
	owltools $(OBO)/$@ --extract-mingraph --set-ontology-id $(OBO)/$@ -o $@
nbo_import.owl: nbo.owl $(EDITSRC) 
	owltools $(UCAT) --map-ontology-iri $(IMP)/$@ $< $(EDITSRC) --extract-module -s $(OBO)/$< -c --make-subset-by-properties  --extract-mingraph --set-ontology-id  -v $(RELEASE)/$@ $(IMP)/$@ -o $@

chebi.owl: uberon.owl
	owltools $(OBO)/$@ --extract-mingraph --rename-entity $(OBO)/chebi#has_part $(OBO)/BFO_0000051 --make-subset-by-properties BFO:0000051 //  --set-ontology-id -v $(RELEASE)/$@ $(OBO)/$@ -o $@
chebi_import.owl: chebi.owl $(EDITSRC) 
	owltools $(UCAT) --map-ontology-iri $(IMP)/$@ $< $(EDITSRC) --extract-module -s $(OBO)/$< -c --extract-mingraph --set-ontology-id -v $(RELEASE)/$@ $(IMP)/$@ -o $@

aminoacid.owl: uberon.owl
	owltools $(OBO)/pr.owl  --reasoner-query -r elk PR_000018263 --reasoner-dispose --make-ontology-from-results $(OBO)/uberon/$@  -o $@
pr.owl: aminoacid.owl
	owltools $< --extract-mingraph --rename-entity $(OBO)/pr#has_part $(OBO)/BFO_0000051 --rename-entity $(OBO)/pr#part_of $(OBO)/BFO_0000050  --make-subset-by-properties BFO:0000050 BFO:0000051 // --split-ontology -d null -l snap --remove-imports-declarations  --remove-dangling --set-ontology-id $(OBO)/$@ -o $@
pr_import.owl: pr.owl $(EDITSRC) 
	owltools $(UCAT) --map-ontology-iri $(IMP)/$@ $< $(EDITSRC) --extract-module -s $(OBO)/$< -c --extract-mingraph --set-ontology-id -v $(RELEASE)/$@ $(IMP)/$@ -o $@

ncbitaxon.owl: uberon.owl
	owltools $(OBO)/ncbitaxon/subsets/taxslim-disjoint-over-in-taxon.owl --merge-import-closure --make-subset-by-properties RO:0002162 // --split-ontology -d null -l cl go caro --remove-imports-declarations --set-ontology-id $(OBO)/$@ -o $@
ncbitaxon_import.owl: ncbitaxon.owl $(EDITSRC) 
	owltools $(UCAT) --map-ontology-iri $(IMP)/$@ $< $(EDITSRC) --extract-module -s $(OBO)/$< -c --extract-mingraph  --remove-dangling-annotations --set-ontology-id -v $(RELEASE)/$@ $(IMP)/$@ -o $@

# CL - take **everything**
cl_import.owl: cl-core.obo uberon.owl
	owltools $(UCAT) $< --extract-mingraph --set-ontology-id -v $(RELEASE)/$@ $(IMP)/$@ -o $@

%_import.obo: %_import.owl uberon.owl
	owltools $< -o -f obo $@

imports: pato_import.obo chebi_import.obo pr_import.obo ncbitaxon_import.obo
	touch $@

# ----------------------------------------
# MAIN RELEASE FILES
# ----------------------------------------

## TODO - restore Disjoints
## TODO - get rid of declarations and inferred subclass axioms for other ontology classes
unreasoned.owl: uberon_edit.owl phenoscape-ext-noimports.owl imports
	owltools $(UCAT) $< phenoscape-ext-noimports.owl --merge-support-ontologies --remove-axioms -t DisjointClasses --remove-axioms -t ObjectPropertyDomain --remove-axioms -t ObjectPropertyRange -o -f functional $@

## TODO - get rid of inferred subclass axioms for other ontology classes
release.owl: unreasoned.owl
	ontology-release-runner --catalog-xml catalog-v001.xml --no-subsets --skip-format owx --outdir newbuild --skip-release-folder  --reasoner elk --simple --asserted --allow-overwrite $< && cp newbuild/uberon/core.owl $@

# this should become the new uberon.owl
#release.owl: unreasoned.owl
#	owltools $(UCAT) $< --assert-inferred-subclass-axioms --useIsInferred --set-ontology-id -v $(RELEASE)/$@ $(OBO)/uberon/$@ -o $@
#release.obo: release.owl
#	owltools $(UCAT) $< -o -f obo $@


# previously we had merged and ext - now just ext. TODO: release/date
ext.owl: release.owl
	owltools $(UCAT) $< --set-ontology-id -v $(RELEASE)/$@ $(OBO)/uberon/$@ -o $@
ext.obo: ext.owl
	owltools $(UCAT) $< --merge-import-closure --make-subset-by-properties BFO:0000050 RO:0002202 immediate_transformation_of // -o -f obo --no-check $@.tmp && obo2obo $@.tmp -o $@

# merged.owl is now the flattening of ext.owl
# merged.obo will be the same as ext.obo
merged.owl: ext.owl
	owltools $(UCAT) $< --merge-import-closure --set-ontology-id -v $(RELEASE)/$@ $(OBO)/uberon/$@ -o $@
merged.obo: merged.owl
	owltools $< -o -f obo --no-check $@.tmp && obo2obo $@.tmp -o $@

# this is like the old uberon.{obo,owl}
uberon.owl: release.owl
	owltools $(UCAT) $< --remove-imports-declarations --remove-dangling --set-ontology-id -v $(RELEASE)/$@ $(OBO)/$@ -o $@
uberon.obo: uberon.owl
	obolib-owl2obo $< -o $@.tmp && obo2obo $@.tmp -o $@


# remember to git mv - this replaces uberon-simple
basic.owl:  uberon.owl
	owltools $< --make-subset-by-properties BFO:0000050 RO:0002202 immediate_transformation_of // --set-ontology-id -v $(RELEASE)/$@ $(OBO)/uberon/$@ -o $@
basic.obo: basic.owl
	obolib-owl2obo $< -o $@.tmp && obo2obo $@.tmp -o $@

subsets/efo-slim.owl: basic.owl
	owltools $< --extract-ontology-subset --subset efo_slim --iri $(OBO)/uberon/$@ -o $@
subsets/efo-slim.obo: subsets/efo-slim.owl
	obolib-owl2obo $< -o $@
subsets/cumbo.owl: basic.owl
	owltools $< --extract-ontology-subset --subset cumbo --iri $(OBO)/uberon/$@ -o $@
subsets/cumbo.obo: subsets/cumbo.owl
	obolib-owl2obo $< -o $@


#TEMPORARY - we will later
supercheck.owl: unreasoned.owl
	owltools $(UCAT) $< phenoscape-ext-noimports.owl --merge-support-ontologies --expand-macros --assert-inferred-subclass-axioms --useIsInferred -o -f functional $@

disjoint-violations.txt: unreasoned.owl
	owltools --no-debug $(UCAT) $< phenoscape-ext-noimports.owl --merge-support-ontologies --expand-macros --reasoner elk --check-disjointness-axioms > $@

newpipe: basic-xp-check

# ----------------------------------------
# SEP MATERIALIZATION
# ----------------------------------------
%-parts.owl: %.owl
	owltools --use-catalog --create-ontology $*-parts  $< --materialize-existentials -p BFO:0000050 --add-imports-from-supports -o $@

# ----------------------------------------
# PRE-JUNE-2013
# ----------------------------------------

all: uberon-qc

# TODO - manage this in OWL
external-disjoints.owl: external-disjoints.obo
	obolib-obo2owl --allow-dangling -o $@ $<

# temp
subsets/taxon-constraints.owl: uberon_edit.obo
	owlrhino js/extract-taxon-constraints.js

taxcheck-%: % subsets/taxon-constraints.owl
	owltools $< subsets/taxon-constraints.owl --add-imports-from-supports --run-reasoner -r elk -u  > $@.tmp && mv $@.tmp $@



# check OE can parse:
# for validation purposes only
%.obo-OE-check: %.obo
	obo2obo -o $@ $<


# ----------------------------------------
# Taxonomy and external AO validation
# ----------------------------------------

# first generate a merged ontology consisting of
#  * core uberon
#  * external-disjoints.owl
#  * species anatomy bridge axioms
# This can be used to reveal both internal inconsistencies within uberon, and the improper linking of a species AO class to an uberon class with a taxon constraint
uberon_edit-plus-tax-equivs.owl: uberon_edit.owl external-disjoints.owl
	owltools --catalog-xml $(CATALOG) $< external-disjoints.owl `ls bridge/uberon-bridge-to-*.owl | grep -v emap.owl` --merge-support-ontologies -o -f functional file://`pwd`/$@
.PRECIOUS: uberon_edit-plus-tax-equivs.owl

# see above
taxon-constraint-check.txt: uberon_edit-plus-tax-equivs.owl
	owltools --no-debug --catalog-xml $(CATALOG) $< --run-reasoner -r elk -u > $@.tmp && mv $@.tmp $@

# BRIDGE CHECKS.
# these can be used to validate on a per-bridge file basis. There are two flavours:
# * quick tests ignore the axioms in the external ontology
# * full tests use these axioms
# note at this time we don't expect all full bridge tests to pass. This is because the disjointness axioms are
# very strong and even seemingly minor variations in representation across ontologies can lead to unsatisfiable classes
# note: exclude EHDAA2 for now until extraembryonic/embryonic issues sorted
## CHECK_AO_LIST = ma emapa ehdaa2 zfa xao fbbt wbbt
CHECK_AO_LIST = ma emapa zfa xao fbbt wbbt
FULL_CHECK_AO_LIST = fma $(CHECK_AO_LIST)
quick-bridge-checks: $(patsubst %,quick-bridge-check-%.txt,$(FULL_CHECK_AO_LIST))
bridge-checks: $(patsubst %,bridge-check-%.txt,$(CHECK_AO_LIST))
full-bridge-checks: $(patsubst %,full-bridge-check-%.txt,$(CHECK_AO_LIST))

# A quick bridge check uses only uberon plus taxon constraints plus bridging axioms, *not* the axioms in the source ontology itself
quick-bridge-check-%.txt: uberon_edit-plus-tax-equivs.owl bridge/bridges external-disjoints.owl
	owltools --no-debug --catalog-xml $(CATALOG) $(OBO)/$*.owl bridge/uberon-bridge-to-$*.owl --merge-support-ontologies --run-reasoner -r elk -u > $@.tmp && mv $@.tmp $@
bridge-check-%.txt: uberon_edit.obo bridge/bridges external-disjoints.owl
	owltools --no-debug --catalog-xml $(CATALOG) $< $(OBO)/$*.owl bridge/uberon-bridge-to-$*.owl external-disjoints.owl --merge-support-ontologies --run-reasoner -r elk -u > $@.tmp && mv $@.tmp $@
full-bridge-check-%.txt: ext.owl bridge/bridges external-disjoints.owl
	owltools --no-debug --catalog-xml $(CATALOG) $< $(OBO)/$*.owl bridge/uberon-bridge-to-$*.owl external-disjoints.owl --merge-support-ontologies --run-reasoner -r elk -u > $@.tmp && mv $@.tmp $@
core-bridge-check-%.txt: core.owl bridge/bridges external-disjoints.owl
	owltools --no-debug --catalog-xml $(CATALOG) $< $(OBO)/$*.owl bridge/uberon-bridge-to-$*.owl external-disjoints.owl --merge-support-ontologies --run-reasoner -r elk -u > $@.tmp && mv $@.tmp $@
# for debugging:

ext-merged-%.owl: ext.owl bridge/bridges external-disjoints.owl
	owltools --catalog-xml $(CATALOG) $< $(OBO)/$*.owl bridge/uberon-bridge-to-$*.owl external-disjoints.owl --merge-imports-closure  --merge-support-ontologies -o $@
.PRECIOUS: ext-merged-%.owl
bridge-dv-check-%.txt: ext-merged-%.owl
	owltools --no-debug $< --reasoner elk --check-disjointness-axioms  > $@.tmp && mv $@.tmp $@


#%.owl: %.obo
#	obolib-obo2owl -o $@ $<


# check for dangling classes
# TODO: add to Oort
%-orphans: %.obo
	obo-grep.pl --neg -r "(is_a|intersection_of|is_obsolete):" $< | obo-grep.pl -r Term - | obo-grep.pl --neg -r "id: UBERON:(0001062|0000000)" - | obo-grep.pl -r Term - > $@.tmp && (egrep '^(id|name):'  $@.tmp > $@ || echo ok)



# TODO: add to Oort
%-xp-check: %.obo
	obo-check-xps.pl $< > $@ 2> $@.err || (echo "problems" && exit 1)


# See: http://douroucouli.wordpress.com/2012/07/03/45/
# TODO - make the OWL primary
depictions.omn: uberon_edit.obo
	./util/mk-image-ont.pl $< > $@
depictions.owl: depictions.omn
	owltools $< -o file://`pwd`/$@

quick-qc: uberon.obo-OE-check core.owl uberon_edit-obscheck.txt
	cat uberon_edit-obscheck.txt

QC_FILES = uberon_edit-xp-check\
    uberon.owl\
    uberon_edit-obscheck.txt\
    uberon.obo\
    uberon.obo-OE-check\
    uberon-obscheck.txt\
    uberon-orphans\
    uberon-synclash\
    external-disjoints.owl\
    depictions.owl\
    bridge/bridges\
    quick-bridge-checks\
    bridge-checks\
    taxon-constraint-check.txt\
    uberon_edit-cycles\
    uberon-cycles\
    uberon.owl\
    uberon-with-isa.obo\
    basic.obo\
    basic-allcycles\
    basic-orphans\
    merged.obo-OE-check\
    merged-cycles\
    merged-orphans\
    ext.owl\
    ext.obo\
    ext-obscheck.txt\
    subsets/efo-slim.obo\
    subsets/cumbo.obo\
    uberon-dv.txt\
    uberon-discv.txt\
    composites\
    composite-metazoan-dv.txt\
    all_taxmods\
#    depictions.owl\


uberon-qc: $(QC_FILES) all_systems
	cat merged-orphans uberon_edit-obscheck.txt uberon_edit-cycles uberon_edit-xp-check.err uberon-cycles uberon-orphans uberon-synclash uberon-dv.txt uberon-discv.txt uberon-simple-allcycles uberon-simple-orphans merged-cycles composite-metazoan-dv.txt 




# Disjoint violations
%-dv.txt: %.owl
	owltools --no-debug $<  --run-reasoner -r elk -u > $@.tmp && grep UNSAT $@.tmp > $@


# TODO - need closure for taxslim too
%-obscheck.txt: %.obo
	((obo-map-ids.pl --ignore-self-refs --use-consider --use-replaced_by $< $<) > /dev/null) >& $@



# ----------------------------------------
# System-specific subsets
# ----------------------------------------
#PA = phenoscape-vocab/phenoscape-anatomy.obo

SYSTEMS = musculoskeletal excretory reproductive digestive nervous sensory immune circulatory pulmonary cranial appendicular

all_systems: $(patsubst %,subsets/%-minimal.obo,$(SYSTEMS)) subsets/life-stages-composite.obo subsets/life-stages-core.obo subsets/life-stages-core.owl subsets/uberon-with-isa-for-FMA-MA-ZFA.obo
PART_OF = BFO_0000050

# TODO: need to add subclass axioms for all intersections
subsets/musculoskeletal-full.obo: merged.owl
	owltools $< --reasoner-query -r elk -d -c $(OBO)/uberon/$@ "$(PART_OF) some UBERON_0002204" -o -f obo file://`pwd`/$@  --reasoner-dispose
subsets/musculoskeletal-minimal.obo: merged.owl
	owltools $< --reasoner-query -r elk -d  "$(PART_OF) some UBERON_0002204" --reasoner-query UBERON_0002204 --make-ontology-from-results $(OBO)/uberon/$@ -o -f obo $@ --reasoner-dispose >& $@.LOG
subsets/excretory-minimal.obo: merged.owl
	owltools $< --reasoner-query -r elk -d  "$(PART_OF) some UBERON_0001008" --reasoner-query UBERON_0001008 --make-ontology-from-results $(OBO)/uberon/$@ -o -f obo $@ --reasoner-dispose >& $@.LOG
subsets/reproductive-minimal.obo: merged.owl
	owltools $< --reasoner-query -r elk -d  "$(PART_OF) some UBERON_0000990" --reasoner-query UBERON_0000990 --make-ontology-from-results $(OBO)/uberon/$@ -o -f obo $@ --reasoner-dispose >& $@.LOG
subsets/digestive-minimal.obo: merged.owl
	owltools $< --reasoner-query -r elk -d  "$(PART_OF) some UBERON_0001007" --reasoner-query UBERON_0001007 --make-ontology-from-results $(OBO)/uberon/$@ -o -f obo $@ --reasoner-dispose >& $@.LOG
subsets/nervous-minimal.obo: merged.owl
	owltools $< --reasoner-query -r elk -d  "$(PART_OF) some UBERON_0001016" --reasoner-query UBERON_0001016 --make-ontology-from-results $(OBO)/uberon/$@ -o -f obo $@ --reasoner-dispose >& $@.LOG
subsets/sensory-minimal.obo: merged.owl
	owltools $< --reasoner-query -r elk -d  "$(PART_OF) some UBERON_0004456" --reasoner-query UBERON_0004456 --make-ontology-from-results $(OBO)/uberon/$@ -o -f obo $@ --reasoner-dispose >& $@.LOG
subsets/immune-minimal.obo: merged.owl
	owltools $< --reasoner-query -r elk -d  "$(PART_OF) some UBERON_0002405" --reasoner-query UBERON_0002405 --make-ontology-from-results $(OBO)/uberon/$@ -o -f obo $@ --reasoner-dispose >& $@.LOG
subsets/circulatory-minimal.obo: merged.owl
	owltools $< --reasoner-query -r elk -d  "$(PART_OF) some UBERON_0001009" --reasoner-query UBERON_0001009 --make-ontology-from-results $(OBO)/uberon/$@ -o -f obo $@ --reasoner-dispose >& $@.LOG
subsets/pulmonary-minimal.obo: merged.owl
	owltools $< --reasoner-query -r elk -d  "$(PART_OF) some UBERON_0001004" --reasoner-query UBERON_0001004 --make-ontology-from-results $(OBO)/uberon/$@ -o -f obo $@ --reasoner-dispose >& $@.LOG
subsets/cranial-minimal.obo: merged.owl
	owltools $< --reasoner-query -r elk -d  "$(PART_OF) some UBERON_0010323" --reasoner-query UBERON_0010323 --make-ontology-from-results $(OBO)/uberon/$@ -o -f obo $@ --reasoner-dispose >& $@.LOG
subsets/appendicular-minimal.obo: merged.owl
	owltools $< --make-subset-by-properties part_of develops_from --reasoner-query -r elk -d  "$(PART_OF) some UBERON_0002091" --reasoner-query UBERON_0002091 --make-ontology-from-results $(OBO)/uberon/$@ -o -f obo $@ --reasoner-dispose >& $@.LOG
subsets/appendicular-ext.owl: #merged.owl
	owltools --use-catalog pe/phenoscape-ext.owl --merge-import-closure --reasoner-query -r elk  -d "$(PART_OF) some UBERON_0002091" --make-subset-by-properties part_of develops_from // --make-ontology-from-results $(OBO)/uberon/$@ --add-ontology-annotation $(DC)/description "this ontology is a derived subset of the phenoscape uberon extension, including only classes that satisfy the query 'part of some appendicular skeleton' " -o file://`pwd`/$@ --reasoner-dispose >& $@.LOG
.PRECIOUS: subsets/appendicular-ext.owl

# TODO - switch to purls for OWL once released
subsets/subsets/life-stages-mammal.owl: subsets/life-stages-core.owl
	owltools $< developmental-stage-ontologies/mmusdv/mmusdv.obo developmental-stage-ontologies/hsapdv/hsapdv.obo --merge-support-ontologies -o file://`pwd`/$@

#subsets/life-stages.obo: uberon.owl
#subsets/life-stages.obo: composite-metazoan.obo
subsets/life-stages-composite.obo: composite-vertebrate.owl
	owltools $< --reasoner-query -r elk -l 'life cycle stage' --make-ontology-from-results $(OBO)/uberon/$@ --add-ontology-annotation $(DC)/description "Life cycle stage subset of uberon composite-vertebrate ontology (includes species stage ontologies)" -o -f obo $@ --reasoner-dispose >& $@.LOG

subsets/life-stages-core.obo: uberon.owl
	owltools $< --reasoner-query -r elk -l 'life cycle stage' --make-ontology-from-results $(OBO)/uberon/$@ --add-ontology-annotation $(DC)/description "Life cycle stage subset of uberon core (generic stages only)" -o -f obo $@ --reasoner-dispose >& $@.LOG
subsets/life-stages-core.owl: uberon.owl
	owltools $< --reasoner-query -r elk -l 'life cycle stage' --make-ontology-from-results $(OBO)/uberon/$@ --add-ontology-annotation $(DC)/description "Life cycle stage subset of uberon core (generic stages only)" -o file://`pwd`/$@ --reasoner-dispose >& $@.LOG


subsets/%.owl: subsets/%.obo
	owltools $< -o file:///`pwd`/$@


# ----------------------------------------
# HISTORIC/LEGACY, NEEDS PRESERVED
# ----------------------------------------

# get rid of non subclass xrefs
%-xf.obo: %.obo
	egrep -v '^xref: (OpenCyc|http)' $< > $@

# used for (obsolete) disjointness checks

# historic
%-with-isa.obo: %-xf.obo
	blip -i $*.obo -u ontol_manifest_has_subclass_from_xref io-convert -to obo -o $@
.PRECIOUS: %-with-isa.obo

# for now we use a simplified set of relations, as this is geared towards analysis
subsets/uberon-with-isa-for-%.obo: uberon.obo
	blip-ddb -i $< -u ontol_manifest_has_subclass_from_selected_xref -u ontol_management -goal "set_selected_idspaces('$*'),retractall(ontol_db:disjoint_from(_,_)),delete_relation_usage_except([develops_from,part_of,continuous_with,capable_of])" io-convert -to obo -o $@
.PRECIOUS: %-with-isa.obo

uberon-isa-to-%.obo: uberon.obo
	obo-grep.pl -r '^id: $*' $< > $@


# @Dep
other-bridges: merged.owl
	owltools $< --extract-bridge-ontologies -d tmp -s uberon -x -o -f obo tmp/minimal.obo

# ----------------------------------------
# CL (to be replaced)
# ----------------------------------------

# core: the full ontology, excluding external classes, but including references to these
# TODO: use --make-subset-by-properties
cl-core.obo: cl.obo
	obo-grep.pl -r 'id: CL:' $< | grep -v ^intersection_of | grep -v ^disjoint | (obo-filter-relationships.pl -t part_of -t capable_of -t develops_from - && cat develops_from.obo part_of.obo has_part.obo capable_of.obo)  > $@

# TODO - this may replace the above BUT need to preserve dangling axioms
cl-core-new.obo: cl.obo
	owltools $< --make-subset-by-properties BFO:0000050 RO:0002202 RO:0002215 // --remove-axioms -t DisjointClasses -o -f obo $@

# this is required for bridging axioms
cl-xrefs.obo:
	blip-findall -r ZFA "entity_xref(Z,C),id_idspace(C,'CL')" -select C-Z -use_tabs -no_pred | tbl2obolinks.pl  --rel xref > $@

cl-core.owl: cl-core.obo
	obolib-obo2owl --allow-dangling $< -o $@

# ----------------------------------------
# OBO-BASIC CHECKS
# ----------------------------------------

# NOTE: we should be able to replace these with oort now
%-cycles: %.obo
#	owltools --no-debug $< --list-cycles -f > $@
	blip-findall -i $< "subclass_cycle/2" -label > $@

%-allcycles: %.owl
	owltools --no-debug $< --list-cycles -f > $@


# TODO: use Oort
%-synclash: %.obo
	blip-findall -r goxp/biological_process_xp_uber_anatomy	 -u query_obo -i $< "same_label_as(X,Y,A,B,C),X@<Y,class_refcount(X,XC),class_refcount(Y,YC)" -select "same_label_as(X,Y,A,B,C,XC,YC)" -label > $@

# ----------------------------------------
# COMPOSITES
# ----------------------------------------


#composites: composite-metazoan.owl composite-vertebrate.owl composite-mammal.owl
composites: composite-metazoan.obo composite-vertebrate.obo

CVERTS = composite-zfa.owl composite-ma.owl composite-xao.owl composite-ehdaa2.owl
CMETS = $(CVERTS) composite-fbbt.owl composite-wbbt.owl
composite-vertebrate.owl: $(CVERTS)
	owltools   --create-ontology uberon/$@ $(CVERTS) --merge-support-ontologies --repair-relations -o $@

composite-metazoan.owl: $(CMETS)
	owltools  --create-ontology -v $(OBO)/uberon/releases/`date +%Y-%m-%d`/composite-metazoan.owl uberon/$@  $(CMETS)  --merge-support-ontologies --repair-relations -o $@

# owl2obo
composite-%.obo: composite-%.owl
	owltools $< -o -f obo --no-check $@.tmp && obo2obo $@.tmp -o $@
#	obolib-owl2obo -o $@ $<

composite-mammal.owl: composite-mammal.obo
	obolib-obo2owl --allow-dangling -o $@ $<
#composite-vertebrate.owl: composite-vertebrate.obo
#	obolib-obo2owl --allow-dangling -o $@ $<


IVSTAGES = -i developmental-stage-ontologies/hsapdv/hsapdv.obo -i developmental-stage-ontologies/mmusdv/mmusdv.obo -i developmental-stage-ontologies/olatdv/olatdv.obo
METAZOAN_ONTS = wbbt zfa fbbt ma ehdaa2 xao
METAZOAN_OBOS = $(patsubst %,local-%.obo,$(METAZOAN_ONTS))
METAZOAN_BRIDGES = $(patsubst %,bridge/uberon-bridge-to-%.owl,$(METAZOAN_ONTS))
local-%.obo: merged.obo
	wget $(OBO)/$*.owl -O cached-$*.owl && owltools cached-$*.owl --repair-relations -o -f obo $@.tmp && egrep -v '^(disjoint|domain|range)' $@.tmp | perl -npe 's/default-namespace: FlyBase development CV/default-namespace: fbdv/' > $@
local-%.owl:
	owltools $(OBO)/$*.owl --repair-relations --rename-entity $(OBO)/$*#develops_in $(OBO)/RO_0002203 --rename-entity $(OBO)/$*#develops_from $(OBO)/RO_0002202 --rename-entity $(OBO)/$*#preceded_by $(OBO)/RO_0002087 --rename-entity $(OBO)/$*#connected_to $(OBO)/UBREL_0000001 --remove-axioms -t DisjointClasses --remove-axioms -t ObjectPropertyRange --remove-axioms -t ObjectPropertyDomain -o -f ofn $@

local-NIF_GrossAnatomy.obo: merged.obo
	wget http://ontology.neuinfo.org/NIF/BiomaterialEntities/NIF-GrossAnatomy.owl -O cached-$@.owl && perl -pi -ne 's@http://ontology.neuinfo.org/NIF/BiomaterialEntities/NIF-GrossAnatomy.owl#@$(OBO)/NIF_GrossAnatomy_@g' cached-$@.owl && owltools cached-$@.owl -o -f obo $@

# NEW:
composite-deps: $(METAZOAN_OBOS)

# many external ontologies do not adhere to all uberon constraints
merged-weak.owl: merged.owl
	owltools $< --remove-axioms -t DisjointClasses --remove-equivalent-to-nothing-axioms -o $@
MBASE = merged-weak.owl

composite-zfa.owl: local-zfa.owl $(MBASE) 
	owltools --no-debug --create-ontology uberon/$@ $(MBASE)  bridge/uberon-bridge-to-zfa.owl bridge/cl-bridge-to-zfa.owl bridge/uberon-bridge-to-zfs.owl $< developmental-stage-ontologies/zfs/zfs.obo --merge-support-ontologies --reasoner elk \
 --merge-species-ontology -s 'Danio' -t NCBITaxon:7954 \
 --assert-inferred-subclass-axioms --removeRedundant --allowEquivalencies \
 -o -f ofn $@

composite-wbbt.owl: local-wbbt.owl $(MBASE)
	owltools --no-debug --create-ontology uberon/$@ $(MBASE)  bridge/uberon-bridge-to-wbbt.owl bridge/cl-bridge-to-wbbt.owl $< --merge-support-ontologies --reasoner elk \
 --merge-species-ontology -s 'C elegans' -t NCBITaxon:6237 \
 --assert-inferred-subclass-axioms --removeRedundant --allowEquivalencies \
 -o -f ofn $@

# TODO - disallow equivalencies
composite-fbbt.owl: local-fbbt.owl local-fbdv.owl $(MBASE) local-fbdv.obo
	owltools --no-debug --create-ontology uberon/$@ $(MBASE)  bridge/uberon-bridge-to-fbbt.owl bridge/cl-bridge-to-fbbt.owl $< local-fbdv.owl --merge-support-ontologies --reasoner elk \
 --merge-species-ontology -s 'Drosophila' -t NCBITaxon:7227 \
 --assert-inferred-subclass-axioms --removeRedundant --allowEquivalencies \
 -o -f ofn $@

composite-ehdaa2.owl: local-ehdaa2.owl $(MBASE)
	owltools --no-debug --create-ontology uberon/$@ $(MBASE)  bridge/uberon-bridge-to-ehdaa2.owl bridge/uberon-bridge-to-hsapdv.owl bridge/cl-bridge-to-ehdaa2.owl $< developmental-stage-ontologies/hsapdv/hsapdv.obo --merge-support-ontologies --remove-axioms -t DisjointClasses --reasoner elk \
 --merge-species-ontology -s 'embryonic human' -t NCBITaxon:9606 \
 --assert-inferred-subclass-axioms --removeRedundant --allowEquivalencies \
 -o -f ofn $@

composite-ma.owl: local-ma.owl $(MBASE) 
	owltools --no-debug --create-ontology uberon/$@ $(MBASE)  bridge/uberon-bridge-to-ma.owl bridge/cl-bridge-to-ma.owl bridge/uberon-bridge-to-mmusdv.owl $< developmental-stage-ontologies/mmusdv/mmusdv.obo --merge-support-ontologies --remove-axioms -t DisjointClasses --reasoner elk \
 --merge-species-ontology -s 'Mus' -t NCBITaxon:10088 \
 --assert-inferred-subclass-axioms --removeRedundant --allowEquivalencies \
 -o -f ofn $@

# TODO
composite-aba.owl: local-aba.owl $(MBASE) 
	owltools --no-debug --create-ontology uberon/$@ $(MBASE)  bridge/uberon-bridge-to-aba.owl aba.obo --merge-support-ontologies --remove-axioms -t DisjointClasses --reasoner elk \
 --merge-species-ontology -s 'Mouse brain' -t NCBITaxon:10088 \
 --assert-inferred-subclass-axioms --removeRedundant --allowEquivalencies \
 -o -f ofn $@

# TODO: fix IRIs
#composite-nif.owl: local-.owl $(MBASE) 
#	owltools --no-debug --create-ontology uberon/$@ $(MBASE)  bridge/uberon-bridge-to-aba.owl aba.obo --merge-support-ontologies --remove-axioms -t DisjointClasses --reasoner elk \
# --merge-species-ontology -s 'Mouse brain' -t NCBITaxon:10088 \
# --assert-inferred-subclass-axioms --removeRedundant --allowEquivalencies \
# -o -f ofn $@

composite-xao.owl: local-xao.owl $(MBASE)
	owltools --no-debug --create-ontology uberon/$@ $(MBASE)  bridge/uberon-bridge-to-xao.owl bridge/cl-bridge-to-xao.owl $< --merge-support-ontologies --remove-axioms -t DisjointClasses --reasoner elk \
 --merge-species-ontology -s 'Xenopus' -t NCBITaxon:8353 \
 --assert-inferred-subclass-axioms --removeRedundant --allowEquivalencies \
 -o -f ofn $@

# @Deprecated
#metazoan_glommed.obo: merged.obo
#	blip io-convert -debug index -i $< -i cl-core.obo -r WBbt -r ZFA -r MA -r EHDAA2 -r XAO -r FBbt $(IVSTAGES) -to obo | egrep -v '^(synonym|def|subset|xref|namespace|comment):' > $@.tmp && mv $@.tmp $@

# closures of individual ontologies, but not connections between them

# ----------------------------------------
# COMPOSITES
# ----------------------------------------





# ----------------------------------------
# TAXON MODULES
# ----------------------------------------
# amniote = 32524
all_taxmods: uberon-taxmod-amniote.obo uberon-taxmod-aves.obo uberon-taxmod-euarchontoglires.obo

uberon-taxmod-aves.owl: uberon-taxmod-8782.owl
	cp $< $@
uberon-taxmod-euarchontoglires.owl: uberon-taxmod-314146.owl
	cp $< $@
uberon-taxmod-amniote.owl: uberon-taxmod-32524.owl
	cp $< $@

uberon-taxmod-%.obo: uberon-taxmod-%.owl
	owltools $(UCAT) $< -o -f obo $@

uberon-taxmod-%.owl: ext.owl
	owltools --use-catalog $< --reasoner elk --make-species-subset -t NCBITaxon:$* --assert-inferred-subclass-axioms --useIsInferred --remove-dangling -o $@ >& $@.log
#uberon-taxmod-%.owl: uberon-taxmod-%.ids
#	blip-ddb -u ontol_db -r uberonp -format "tbl(ids)" -i $< -goal "forall((class(C),\+ids(C)),delete_class(C)),remove_dangling_facts" io-convert -to obo > $@
#	blip ontol-query -r uberonp -format "tbl(ids)" -i $< -to obo -query "ids(ID)" > $@.tmp && grep -v ^disjoint_from $@.tmp | grep -v 'relationship: spatially_disjoint' > $@
.PRECIOUS: uberon-taxmod-%.owl


#taxtable.txt: uberon_edit.obo
#	owltools $< --make-class-taxon-matrix --query-taxa external/ncbitaxon-subsets/taxslim.obo -o z NCBITaxon:9606 NCBITaxon:7955


# ----------------------------------------
# BRIDGES
# ----------------------------------------

bridge/bridges: bridge/uberon-bridge-to-vhog.owl seed.obo cl-with-xrefs.obo
	cd bridge && ../make-bridge-ontologies-from-xrefs.pl ../seed.obo && ../make-bridge-ontologies-from-xrefs.pl -b cl ../cl-with-xrefs.obo ../cl-xrefs.obo && touch bridges

cl-with-xrefs.obo: cl-core.obo 
	grep ^treat- uberon_edit.obo > $@ && cat $< >> $@

bridge/uberon-bridge-to-vhog.owl: uberon_edit.obo
	./util/mk-vhog-individs.pl organ_association_vHOG.txt uberon_edit.obo > $@.ofn && owltools $@.ofn -o file://`pwd`/$@

bridge/uberon-bridge-to-emap.obo: mapping_EMAP_to_EMAPA.txt
	blip ontol-query -r emapa -r emap -consult util/emap_to_cdef.pro -i $< -i uberon.obo -i developmental-stage-ontologies/mmusdv/mmusdv.obo -query "mapping_EMAP_to_EMAPA(ID,_,_)" -to obo | perl -npe 's/OBO_REL://' > $@.tmp && ./util/emap-to-cdef-add-hdr.pl $@.tmp > $@
.PRECIOUS: bridge/uberon-bridge-to-emap.obo
bridge/uberon-bridge-to-emap.owl: bridge/uberon-bridge-to-emap.obo
	obolib-obo2owl --allow-dangling $< -o $@

# DO NOT REMAKE ANY MORE: See #157
bridge/ext-xref-PREVIEW.obo:
	blip-findall -r pext -r ZFA -i pe/tao-obsoletions.obo "entity_xref(Z,T),entity_replaced_by(T,U),\+id_idspace(Z,'UBERON'),id_idspace(U,'UBERON')" -select U-Z -label -use_tabs -no_pred | tbl2obolinks.pl --rel xref - > $@.tmp && cat ext-ref-hdr.obo $@.tmp > $@
bridge/uberon-ext-bridge-to-zfa.obo: bridge/ext-xref.obo
	cd bridge && ../make-bridge-ontologies-from-xrefs.pl -b uberon-ext ext-xref.obo

# see #157
ext-xref-conflict.obo:
	blip-findall -r pext -r ZFA -i pe/tao-obsoletions.obo "entity_xref(Z,T),entity_replaced_by(T,U),\+id_idspace(Z,'UBERON'),id_idspace(U,'UBERON'),entity_xref(U,Zx),id_idspace(Zx,'ZFA'),Zx\=Z" -select "x(U,Z,Zx)" -label > $@
ext-xref-conflict2.obo:
	blip-findall -r pext -r ZFA -i pe/tao-obsoletions.obo "entity_xref(Z,T),entity_replaced_by(T,U),\+id_idspace(Z,'UBERON'),id_idspace(U,'UBERON'),entity_xref(Ux,Z),id_idspace(Ux,'UBERON'),Ux\=U" -select "x(U,Z,Ux)" -label > $@

release-diff:
	cd diffs && make

# ----------------------------------------
# RELEASE DEPLOYMENT
# ----------------------------------------
# even tho the repo lives in github, release is via svn...

RELDIR=trunk
release:
	cp uberon_edit.owl $(RELDIR)/core.owl ;\
	cp uberon_edit.obo $(RELDIR)/core.obo ;\
	cp uberon.{obo,owl} $(RELDIR) ;\
	cp merged.{obo,owl} $(RELDIR)/ ;\
	cp basic.obo $(RELDIR)/basic.obo ;\
	cp basic.owl $(RELDIR)/basic.owl ;\
	cp *_import.owl $(RELDIR)/ ;\
	cp bridge/*.{obo,owl} $(RELDIR)/bridge/ ;\
	cp depictions.owl $(RELDIR)/ ;\
	cp ext.{obo,owl} $(RELDIR)/ ;\
	cp external-disjoints.{obo,owl} $(RELDIR)/ ;\
	cp external-disjoints.{obo,owl} $(RELDIR)/bridge/ ;\
	cp subsets/*.{obo,owl} $(RELDIR)/subsets/ ;\
	cp uberon-taxmod-amniote.obo $(RELDIR)/subsets/amniote-basic.obo ;\
	cp uberon-taxmod-amniote.owl $(RELDIR)/subsets/amniote-basic.owl ;\
	cp uberon-taxmod-aves.obo $(RELDIR)/subsets/aves-basic.obo ;\
	cp uberon-taxmod-aves.owl $(RELDIR)/subsets/aves-basic.owl ;\
	cp uberon-taxmod-euarchontoglires.obo $(RELDIR)/subsets/euarchontoglires-basic.obo ;\
	cp uberon-taxmod-euarchontoglires.owl $(RELDIR)/subsets/euarchontoglires-basic.owl ;\
	cp composite-{vertebrate,metazoan}.{obo,owl} $(RELDIR) ;\
	cp reference/*{owl,html} reference/*[0-9] $(RELDIR)/reference  ;\
	make release-diff ;\
	cp diffs/* $(RELDIR)/diffs/ ;\
	echo done ;\
#	cd $(RELDIR) && svn commit -m ''



# ----------------------------------------
# RELEASE
# ----------------------------------------
aao.obo:
	wget $(OBO)/aao.obo

fbbt.obo:
	wget $(OBO)/fbbt.obo

# See: http://code.google.com/p/caro2/issues/detail?id=10
bridge/fbbt-nd.obo: fbbt.obo
	grep -v ^disjoint $< | perl -npe 's@^ontology: fbbt@ontology: uberon/fbbt-nd@' > $@.tmp && obo2obo $@.tmp -o $@




# ///////////////////////
# ///////////////////////
# ///  odds and ends ////
# ///////////////////////
# ///////////////////////

# ----------------------------------------
# OTHER
# ----------------------------------------

xrefs/uberon-to-umls.tbl: uberon.obo
	blip-findall -r NCITA  -i $< "entity_xref(U,X),inst_sv(X,'\"UMLS_CUI\"',C,_)" -select U-C -no_pred -label -use_tabs > $@.tmp && mv $@.tmp $@

xrefs/uberon-to-umls.obo: uberon.obo
	blip-findall -r NCITA  -i $< "entity_xref(U,X),inst_sv(X,'\"UMLS_CUI\"',C,_),atom_concat('UMLS:',C,CX)" -select U-CX -no_pred -use_tabs | tbl2obolinks.pl --rel xref  > $@.tmp && mv $@.tmp $@
xrefs/uberon-to-umls-merged.obo: xrefs/uberon-to-umls.obo
	obo-merge-tags.pl -t xref uberon_edit.obo $< > $@ && diff -u $@ uberon_edit.obo || echo



# OBO-Format Hacking
%-cmt.obo: %.obo
	obo-add-comments.pl -t xref -t intersection_of uberon_edit.obo animal_gross_anatomy/*/*.obo ../cell_type/cell.obo ../caro/caro.obo MIAA.obo animal_gross_anatomy/*/*/*.obo ~/cvs/fma-conversion/fma2/fma2.obo gemina_anatomy.obo birnlex_anatomy.obo NIF-GrossAnatomy.obo hao.obo HOG.obo efo_anat.obo $< > $@

caloha.obo:
	wget ftp://ftp.nextprot.org/pub/current_release/controlled_vocabularies/caloha.obo -O $@


xcaloha.obo: caloha.obo
	perl -npe 's/TS\-/CALOHA:TS\-/g' $< > $@

#
uberon-new-mp.obo:
	blip -u query_anatomy -i uberon_edit.obo -r cell -r emap -r EMAPA -r mammalian_phenotype -r mammalian_phenotype_xp  -r fma_downcase -r NIFGA -r zebrafish_anatomy  -r mouse_anatomy findall uberon_mpxp_write > $@

uberon-new-hp.obo:
	blip -u query_anatomy -i uberon_edit.obo -r cell -r human_phenotype -r human_phenotype_xp -r NIFGA -r zebrafish_anatomy -r mouse_anatomy -r EMAPA -goal "uberon_mpxp_write,halt" > $@

uberon-new-go.obo:
	blip -u query_anatomy -i uberon_edit.obo -r cell -r go -r goxp/biological_process_xp_uber_anatomy -r NIFGA -r zebrafish_anatomy -r mouse_anatomy -r EMAPA -r goxp/biological_process_xp_fly_anatomy -r goxp/biological_process_xp_plant_anatomy -r goxp/biological_process_xp_zebrafish_anatomy -goal "uberon_goxp_write,halt" > $@

cl-new-go.obo:
	blip -u query_anatomy -i uberon_edit.obo -r cell -r go -r goxp/biological_process_xp_uber_anatomy -r goxp/biological_process_xp_cell  -r zebrafish_anatomy -r mouse_anatomy -r EMAPA -r goxp/biological_process_xp_fly_anatomy -r goxp/biological_process_xp_plant_anatomy -r goxp/biological_process_xp_zebrafish_anatomy -goal "cl_goxp_write,halt" > $@

uberon-defs-from-mp.obo:
	blip -u query_anatomy -i uberon_edit.obo -r mammalian_phenotype  -goal "uberon_mpxp_write_defs,halt" > $@

%.xrefcount: %.obo
	blip -i $< -u ontol_db findall -label '(class(C),setof_count(X,class_xref(C,X),Num))' -select 'C-Num' | sort -k3 -n > $@

caloha-not-in-uberon.txt: 
	blip-findall -consult util/ubxref.pro -i uberon.obo -r caloha "class(X),atom_concat('TS-',_,X),\+ubxref(_,X)" -select X -label

# ----------------------------------------
# Rules
# ----------------------------------------

ipo.obo: uberon.obo
	blip-findall  -i $< -consult util/partof.pro new_part_of/2 -label -no_pred -use_tabs | sort -u | tbl2obolinks.pl  --rel part_of --source reference_0000032 - > $@

# ----------------------------------------
# REPORTING
# ----------------------------------------

# DOCS
relation_table.txt:
	blip-findall -r uberon -consult util/relation_report.pro "row(R)" -select R > relation_table.txt

%-relstats: %.obo
	blip-findall -r uberon  "aggregate(count,X-T,parent(X,R,T),Num)" -select "R-Num" -no_pred | | sort -nk2 > $@

%-el.owl: %.owl
	makeElWithoutReasoning.sh -i `pwd`/$< -o `pwd`/$@

# ----------------------------------------
# wikipedia
# ----------------------------------------

%-wikipedia.xrefs: %.obo
	(blip -i $< -u web_fetch_wikipedia -u query_anatomy findall class_wikipage/2 > $@) >& $@.err

%-wikipedia.pro: %-wikipedia.xrefs
	./wikitbl2defxref.pl $< | tbl2p > $@

%-wikipedia.merge: %-wikipedia.xrefs
	./wikitbl2defxref.pl $< | cut -f2,3 | tbl2obolinks.pl --rel xref > $@

#nif_anatomy.obo:
#	blip -i http://ontology.neuinfo.org/NIF/BiomaterialEntities/NIF-GrossAnatomy.owl -f thea2_owl -import_all io-convert -to obo -u ontol_manifest_metadata_from_nif_via_thea -o $@.tmp && ./downcase-obo.pl $@.tmp > $@

nif_subcellular.obo:
	blip -i http://ontology.neuinfo.org/NIF/BiomaterialEntities/NIF-Subcellular.owl -f thea2_owl -import_all io-convert -to obo -u ontol_manifest_metadata_from_nif_via_thea -o $@.tmp && ./nif-downcase-obo.pl $@.tmp > $@

nif_cell.obo:
	blip -i http://ontology.neuinfo.org/NIF/BiomaterialEntities/NIF-Cell.owl -f thea2_owl -import_all io-convert -to obo -u ontol_manifest_metadata_from_nif_via_thea -o $@.tmp && ./nif-downcase-obo.pl $@.tmp > $@

# VHOG
organ_association.txt:
	wget http://bgee.unil.ch/download/organ_association.txt

stages.obo:
	wget http://bgee.unil.ch/download/stages.obo

mapping_EMAP_to_EMAPA.txt:
	wget ftp://lausanne.isb-sib.ch/pub/databases/Bgee/general/mapping_EMAP_to_EMAPA.txt


# ----------------------------------------
# VIEWS
# ----------------------------------------
%-partview.owl: %.owl
	owltools $< --remove-subset grouping_class --remove-subset upper_level --bpvo --reflexive --prefix "" --suffix " part" -r elk -p BFO:0000050 --replace --set-ontology-id $(OBO)/uberon/$@ -o -f ttl $@
##	owltools $< --bpvo --prefix "" --suffix " part" -r elk -p BFO:0000050 --set-ontology-id $(OBO)/uberon/$@ -o $@

%-exprview.owl: %.owl
	owltools --use-catalog $< $(OBO)/ro.owl --merge-support-ontologies  --remove-subset grouping_class --remove-subset upper_level --bpvo  --prefix " expressed in" --suffix "" -r elk -p BFO:0000050 --replace --set-ontology-id $(OBO)/uberon/$@ -o -f ttl $@


# ----------------------------------------
# TEXT MINING
# ----------------------------------------

%-matches.tbl: %.txt
	 blip-findall  -debug index -index "metadata_nlp:entity_label_token_list_stemmed(1,0,0,0)" -u metadata_nlp -i $< -r cell -r uberon "$*(X),label_full_parse(X,true,S)" -select "m(X,S)" -label > $@

# ----------------------------------------
# DBPEDIA
# ----------------------------------------

# note that dbpedia vastly underclassifies here.
# 4k limit seems unusual...
dbpedia_all_AnatomicalStructure.pro:
	 blip -debug sparql ontol-sparql-remote "SELECT * WHERE {  ?x rdf:type <http://dbpedia.org/ontology/AnatomicalStructure> }" -write_prolog > $@.tmp && sort -u $@.tmp > $@

# this should be subsumed by AnatomicalStructure
dbpedia_all_Embryology.pro:
	 blip ontol-sparql-remote "SELECT * WHERE {  ?x rdf:type <http://dbpedia.org/ontology/Embryology> }" -write_prolog > $@.tmp && sort -u $@.tmp > $@

dbpedia_all_Animal_anatomy.pro:
	 blip ontol-sparql-remote "SELECT * WHERE {  ?x <http://purl.org/dc/terms/subject> <http://dbpedia.org/resource/Category:Animal_anatomy> }" -write_prolog > $@.tmp && sort -u $@.tmp > $@

dbpedia_all_Mammal_anatomy.pro:
	 blip ontol-sparql-remote "SELECT * WHERE {  ?x <http://purl.org/dc/terms/subject> <http://dbpedia.org/resource/Category:Mammal_anatomy> }" -write_prolog > $@.tmp && sort -u $@.tmp > $@

dbpedia_category_%.pro:
	 blip ontol-sparql-remote "SELECT * WHERE {  ?x <http://purl.org/dc/terms/subject> <http://dbpedia.org/resource/Category:$*> }" -write_prolog > $@.tmp && sort -u $@.tmp > $@
.PRECIOUS: dbpedia_category_%.pro

dbpedia_type_%.pro:
	 blip ontol-sparql-remote "SELECT * WHERE {  ?x rdf:type dbpedia-owl:$* }" -write_prolog > $@.tmp && sort -u $@.tmp > $@

dbpedia_TH.pro:
	 blip ontol-sparql-remote "SELECT ?x,?y WHERE {  ?x <http://dbpedia.org/property/code> ?y . FILTER strStarts(str(?y),'TH H')  }" -write_prolog > $@.tmp && sort -u $@.tmp > $@


dbpedia_all_Bone.pro:
	 blip ontol-sparql-remote "SELECT * WHERE {  ?x rdf:type dbpedia-owl:Bone }" -write_prolog > $@.tmp && sort -u $@.tmp > $@
dbpedia_all_Nerve.pro:
	 blip ontol-sparql-remote "SELECT * WHERE {  ?x rdf:type dbpedia-owl:Nerve }" -write_prolog > $@.tmp && sort -u $@.tmp > $@

dbpedia_subjects.pro:
	sort -u dbpedia_all_*.pro > $@

triples-%.pro: %.pro
	blip-findall -debug sparql -i $< -u sparql_util "row(A),dbpedia_query_links(A,row(S,P,O),1000,[])" -select "rdf(S,P,O)" -write_prolog > $@
#	blip-findall -debug sparql -i $< -u sparql_util "row(A),dbpedia_query_links(A,row(S,P,O),1000,[sameAs('http://dbpedia.org/property/redirect')])" -select "rdf(S,P,O)" -write_prolog > $@
.PRECIOUS: triples-%.pro

dbpo-%.obo: triples-%.pro
	blip -i $< -u ontol_bridge_from_dbpedia io-convert -to obo > $@


# everything as type AnatomicalStructure
dbpedia_all.pro: dbpedia_subjects.pro
	blip-findall -debug sparql -i $< -u sparql_util "row(A),dbpedia_query_links(A,row(S,P,O),1000,[])" -select "rdf(S,P,O)" -write_prolog > $@
dbpedia_all-after-%.pro: dbpedia_all_AnatomicalStructure.pro
	blip-findall -debug sparql -i $< -u sparql_util "row(A),A@>'http://dbpedia.org/resource/$*',dbpedia_query_links(A,row(S,P,O),1000,[])" -select "rdf(S,P,O)" -write_prolog > $@

# everything with a def_xref to wikipedia
dbpedia_rest.pro: dbpedia_all_AnatomicalStructure.pro
	blip-findall -i adhoc_uberon.pro -r uberon -i $< -u sparql_util "def_xref(C,X),wpxref_url(X,_,A),\+row(A),dbpedia_query_links(A,row(S,P,O),1000,[])" -select "rdf(S,P,O)" -write_prolog > $@

dbpedia_ontol.obo: dbpedia_all.pro
	blip -i $< -u ontol_bridge_from_dbpedia io-convert -to obo > $@

uberon-thumbnail-xrefs.obo: dbpedia_all.pro
	blip-findall -r uberonp -i dbpedia_all.pro -i adhoc_uberon.pro uberon_thumbnail/2 -label | cut -f2,3 | tbl2obolinks.pl --rel xref > $@

# MUSCLES
dbpedia-muscles: dbpedia-muscle-origin-x.obo dbpedia-muscle-insertion-x.obo dbpedia-muscle-nerve-x.obo  dbpedia-muscle-action-x.obo dbpedia-muscle-antagonist-x.obo dbpedia-muscle-agonist-x.obo
dbpedia-muscle-%.pro:
	blip ontol-sparql-remote "SELECT * WHERE { ?x dbpprop:$* ?y. ?x rdf:type dbpedia-owl:Muscle}" -write_prolog > $@.tmp && mv $@.tmp $@
.PRECIOUS: dbpedia-muscle-%.pro

dbpedia-muscle-%-x.obo: dbpedia-muscle-%.pro
	blip-findall -debug match -consult util/dbpedia_to_link.pro -r uberon -i $< "wfact($*)" > $@.tmp && mv $@.tmp $@

dbpedia-t-muscle-%.pro: dbpedia-muscle-%.pro
	blip-findall -i $< "row(A,B)" -select "row(A,'$*',B)" -write_prolog > $@

dbpedia-ALL-muscle.pro: dbpedia-t-muscle-origin.pro dbpedia-t-muscle-insertion.pro dbpedia-t-muscle-nerve.pro  dbpedia-t-muscle-action.pro dbpedia-t-muscle-antagonist.pro 
	cat dbpedia-t-muscle-*.pro > $@

dbpedia-muscle-nlp.obo: dbpedia-ALL-muscle.pro
	blip-findall -debug match -consult util/dbpedia_to_link.pro -r uberon -u annotator -i $< "initialize_annotator,wfact_nlp" > $@.tmp && mv $@.tmp $@


dbpredia-props: dbpedia-prop-articulations-x.obo

dbpedia-prop-%.pro:
	blip ontol-sparql-remote "SELECT * WHERE { ?x dbpprop:$* ?y}" -write_prolog > $@.tmp && mv $@.tmp $@
.PRECIOUS: dbpedia-prop-%.pro

dbpedia-prop-%-x.obo: dbpedia-prop-%.pro
	blip-findall -debug match -consult util/dbpedia_to_link.pro -r uberon -i $< "wfact($*)" > $@.tmp && mv $@.tmp $@

dbpedia-latin.pro:
	blip ontol-sparql-remote "SELECT * WHERE { ?x dbpprop:latin ?y. ?x rdf:type dbpedia-owl:AnatomicalStructure}" -write_prolog > $@.tmp && mv $@.tmp $@

dbpedia-depiction.pro:
	blip ontol-sparql-remote "SELECT * WHERE { ?x foaf:depiction ?y. ?x rdf:type dbpedia-owl:AnatomicalStructure}" -write_prolog > $@.tmp && mv $@.tmp $@

dbpedia-redirects.pro:
	blip ontol-sparql-remote "SELECT * WHERE { ?y dbpedia-owl:wikiPageRedirects ?x. ?x rdf:type dbpedia-owl:AnatomicalStructure}" -write_prolog > $@.tmp && mv $@.tmp $@
dbpedia-disambig.pro:
	blip ontol-sparql-remote "SELECT * WHERE { ?y dbpedia-owl:wikiPageDisambiguates ?x. ?x rdf:type dbpedia-owl:AnatomicalStructure}" -write_prolog > $@.tmp && mv $@.tmp $@

dbpedia-list-AS.txt:
	blip -debug sparql ontol-sparql-remote "SELECT * WHERE { ?x rdf:type dbpedia-owl:AnatomicalStructure}" > $@.tmp && mv $@.tmp $@

# then do obo-add-defs.pl defs.txt uberon_edit.obo
defs.txt:
	blip-findall -i dbpedia_all.pro -r uberon -i adhoc_uberon.pro "class_newdef(C,D)" | cut -f2,3 > $@

syns.txt:
	blip-findall -index "metadata_nlp:entity_label_token_stemmed(1,0,1,0)" -i dbpedia_all.pro -r uberon -i adhoc_uberon.pro "dbpedia_syn(C,S),class(C,N)" -select "s(C,N,S)" > $@

df.txt:
	blip-findall -i dbpedia_all.pro -r uberon -i adhoc_uberon.pro "dbpedia_devfrom(Post,Pre)" -select Post-Pre | cut -f2,3 > $@

new.txt:
	blip-findall -i dbpedia_all.pro -r uberon -i adhoc_uberon.pro "dbpedia_new(C)" -select C > $@

ma2ncitx.obo: ma2ncit.obo
	blip-findall -r MA -i $<  -r NCITA "class_xref(M,MX),atom_concat('ncithesaurus:',X,MX),inst_sv(C,_P,X,_)" -select "M-C" -no_pred -label -use_tabs | sort -u | tbl2obolinks.pl --rel xref - > $@

# ----------------------------------------
# BTO
# ----------------------------------------
bto-anat.obo:
	blip ontol-query -r brenda -index "ontol_db:parentT(1,-,1)" -query "parentT(ID,'BTO:0000042'),\+((class(X,N),atom_concat(_,'cell line',N),parentT(ID,X)))" -to obo  > $@

# ----------------------------------------
# ABA
# ----------------------------------------

aba.obo: ABA-src.obo
	./util/make-aba-part-ofs.pl $< > $@
bridge/aba.owl: aba.obo
	owltools $< -o file://`pwd`/$@

# ----------------------------------------
# NIF
# ----------------------------------------
NIF = 
source-ontologies/NIF-GrossAnatomy-src.owl:
	wget http://ontology.neuinfo.org/NIF/BiomaterialEntities/NIF-GrossAnatomy.owl -O $@
source-ontologies/NIF-GrossAnatomy.owl: source-ontologies/NIF-GrossAnatomy-src.owl
	perl -npe 's@http://ontology.neuinfo.org/NIF/BiomaterialEntities/NIF-GrossAnatomy.owl#@http://purl.obolibrary.org/obo/NIF_GrossAnatomy_@g' $< > $@
#	perl -npe 's@http://ontology.neuinfo.org/NIF/BiomaterialEntities/NIF-GrossAnatomy.owl#@http://purl.obolibrary.org/obo/NIF_GrossAnatomy:@g' $< > $@

source-ontologies/NIF-GrossAnatomy-orig.obo: source-ontologies/NIF-GrossAnatomy.owl
	owltools $< -o -f obo $@
source-ontologies/NIF-GrossAnatomy.obo: source-ontologies/NIF-GrossAnatomy-orig.obo
	./util/fix-nif-ga.pl $< > $@

uberon-nif-combined.owl: uberon.owl
	owltools $< bridge/uberon-bridge-to-nif_grossanatomy.owl source-ontologies/NIF-GrossAnatomy.owl --merge-support-ontologies -o $@

#uberon-nif-combined.obo: uberon.obo
#	obo-cat.pl uberon.obo bridge/uberon-bridge-to-nif_grossanatomy.obo ~/cvs/pkb-owl/ontology.neuinfo.org/NIF/BiomaterialEntities/NIF-GrossAnatomy.obo > $@

uberon-nif-merged.owl: uberon-nif-combined.obo
	owltools $< --reasoner elk  --merge-equivalent-classes -f  -t UBERON -o $@.tmp && grep -v '<oboInOwl:id' $@.tmp > $@
#	owltools $< --reasoner elk --remove-axioms -t DisjointClasses --merge-equivalent-classes -a  -t UBERON -o $@.tmp && grep -v '<oboInOwl:id' $@.tmp > $@

uberon-nif-merged.obo:  uberon-nif-merged.owl
	owltools $< -o -f obo --no-check $@

source-ontologies/NeuroNames.obo: source-ontologies/NeuroNames.xml
	./util/nn2obo.pl $< > $@

# ----------------------------------------
# UTIL
# ----------------------------------------
util/ubermacros.el:
	blip-findall  -r pext -r taxslim -consult util/write_ubermacros.pro  w > $@
