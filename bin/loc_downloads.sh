#!/usr/bin/env bash

# LOC downloads are available at http://id.loc.gov/download/

if [ ! -s authoritiesnames_madsrdf.nt ]; then
    wget -c http://id.loc.gov/static/data/authoritiesnames.nt.madsrdf.gz
    gunzip authoritiesnames.nt.madsrdf.gz
    mv authoritiesnames.nt.madsrdf authoritiesnames_madsrdf.nt
fi

wget -c http://id.loc.gov/static/data/authoritiessubjects.nt.madsrdf.zip
unzip -o authoritiessubjects.nt.madsrdf.zip
# created subjects-madsrdf-20140306.nt

# Skipping skos because most of the data is in madsrdf.
#if [ ! -s  authoritiesnames_skos.nt ]; then
#    wget -c http://id.loc.gov/static/data/authoritiesnames.nt.skos.gz
#    gunzip authoritiesnames.nt.skos.gz
#    mv authoritiesnames.nt.skos authoritiesnames_skos.nt
#fi

# Skipping skos because most of the data is in madsrdf.
#wget -c http://id.loc.gov/static/data/authoritiessubjects.nt.skos.zip
#unzip -o authoritiessubjects.nt.skos.zip

wget -c http://id.loc.gov/static/data/authoritieschildrensSubjects.nt.zip
unzip -o authoritieschildrensSubjects.nt.zip

wget -c http://id.loc.gov/static/data/authoritiesgenreForms.nt.zip
unzip -o authoritiesgenreForms.nt.zip

wget -c http://id.loc.gov/static/data/authoritiesperformanceMediums.nt.zip
unzip -o authoritiesperformanceMediums.nt.zip

wget -c http://id.loc.gov/static/data/vocabularycountries.nt.zip
unzip -o vocabularycountries.nt.zip

wget -c http://id.loc.gov/static/data/vocabularyethnographicTerms.nt.zip
unzip -o vocabularyethnographicTerms.nt.zip

wget -c http://id.loc.gov/static/data/vocabularygeographicAreas.nt.zip
unzip -o vocabularygeographicAreas.nt.zip

wget -c http://id.loc.gov/static/data/vocabularygraphicMaterials.nt.zip
unzip -o vocabularygraphicMaterials.nt.zip

wget -c http://id.loc.gov/static/data/vocabularyiso639-1.nt.zip
unzip -o vocabularyiso639-1.nt.zip
wget -c http://id.loc.gov/static/data/vocabularyiso639-2.nt.zip
unzip -o vocabularyiso639-2.nt.zip
wget -c http://id.loc.gov/static/data/vocabularyiso639-5.nt.zip
unzip -o vocabularyiso639-5.nt.zip

wget -c http://id.loc.gov/static/data/vocabularylanguages.nt.zip
unzip -o vocabularylanguages.nt.zip

wget -c http://id.loc.gov/static/data/vocabularyorganizations.nt.zip
unzip -o vocabularyorganizations.nt.zip

wget -c http://id.loc.gov/static/data/vocabularyrelators.nt.zip
unzip -o vocabularyrelators.nt.zip

