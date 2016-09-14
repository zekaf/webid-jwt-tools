#!/usr/bin/python
# dependencies:
# pip install rdfextras rdflib rdflib-sparql

import sys
import rdflib
from rdflib import Graph

profile_doc = sys.argv[1]

g = Graph()
g.parse(profile_doc)

query = """
SELECT ?namecoin WHERE {
   ?wallet cc:namecoin ?namecoin .
}
"""
for row in g.query(query):
   print row
