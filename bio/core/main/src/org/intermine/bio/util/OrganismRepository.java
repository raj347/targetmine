package org.intermine.bio.util;

/*
 * Copyright (C) 2002-2008 FlyMine
 *
 * This code may be freely distributed and modified under the
 * terms of the GNU Lesser General Public Licence.  This should
 * be distributed with the code.  See the LICENSE file for more
 * information or http://www.gnu.org/copyleft/lesser.html.
 *
 */

import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import java.io.IOException;
import java.io.InputStream;

/**
 * A class to hold information about organisms.
 * @author Kim Rutherford
 */
public class OrganismRepository
{
    private static OrganismRepository or = null;
    private Map<Integer, OrganismData> taxonMap = new HashMap<Integer, OrganismData>();
    private Map<String, OrganismData> abbreviationMap = new HashMap<String, OrganismData>();

    private static final String PROP_FILE = "organism_config.properties";
    private static final String PREFIX = "taxon";

    private static final String ABBREVIATION = "abbreviation";
    private static final String GENUS = "genus";
    private static final String SPECIES = "species";

    private static final String REGULAR_EXPRESSION =
        PREFIX + "\\.(\\d+)\\.(" + SPECIES + "|" + GENUS + "|" + ABBREVIATION + ")";

    private OrganismRepository() {
        // empty
    }

    /**
     * Return an OrganismRepository created from a properties file in the class path.
     * @return the OrganismRepository
     */
    public static OrganismRepository getOrganismRepository() {
        if (or == null) {
            Properties props = new Properties();
            try {
                InputStream propsResource =
                    OrganismRepository.class.getClassLoader().getResourceAsStream(PROP_FILE);
                if (propsResource == null) {
                    throw new RuntimeException("can't find " + PROP_FILE + " in class path");
                } else {
                    props.load(propsResource);
                }
            } catch (IOException e) {
                throw new RuntimeException("Problem loading properties '" + PROP_FILE + "'", e);
            }

            or = new OrganismRepository();

            Enumeration propNames = props.propertyNames();

            Pattern pattern = Pattern.compile(REGULAR_EXPRESSION);

            while (propNames.hasMoreElements()) {
                String name = (String) propNames.nextElement();
                if (name.startsWith(PREFIX)) {
                    Matcher matcher = pattern.matcher(name);
                    if (matcher.matches()) {
                        String taxonIdString = matcher.group(1);
                        int taxonId = Integer.valueOf(taxonIdString).intValue();
                        String fieldName = matcher.group(2);

                        OrganismData od = or.getOrganismDataByTaxonInternal(taxonId);
                        final String abbreviation = props.getProperty(name);
                        if (fieldName.equals(ABBREVIATION)) {
                            od.setAbbreviation(abbreviation);
                            or.abbreviationMap.put(abbreviation, od);
                        } else {
                            if (fieldName.equals(SPECIES)) {
                                od.setSpecies(abbreviation);
                            } else {
                                if (fieldName.equals(GENUS)) {
                                    od.setGenus(abbreviation);
                                } else {
                                    throw new RuntimeException("internal error didn't match: "
                                                               + fieldName);
                                }
                            }
                        }
                    } else {
                        throw new RuntimeException("unable to parse organism property key: "
                                                   + name);
                    }
                } else {
                    throw new RuntimeException("properties in " + PROP_FILE + " must start with "
                                               + PREFIX + ".");
                }
            }
        }

        return or;
    }

    /**
     * Look up OrganismData objects by taxon id.  Create and return a new OrganismData object if
     * there is no existing one.
     * @param taxonId the taxon id
     * @return the OrganismData
     */
    public OrganismData getOrganismDataByTaxonInternal(int taxonId) {
        OrganismData od = taxonMap.get(taxonId);
        if (od == null) {
            od = new OrganismData();
            od.setTaxonId(taxonId);
            taxonMap.put(taxonId, od);
        }
        return od;
    }

    /**
     * Look up OrganismData objects by taxon id.  Return null if there is no such organism.
     * @param taxonId the taxon id
     * @return the OrganismData
     */
    public OrganismData getOrganismDataByTaxon(Integer taxonId) {
        return taxonMap.get(taxonId);
    }

    /**
     * Look up OrganismData objects by abbreviation.  Return null if there is no such organism.
     * @param abbreviation the abbreviation
     * @return the OrganismData
     */
    public OrganismData getOrganismDataByAbbreviation(String abbreviation) {
        return abbreviationMap.get(abbreviation);
    }
}
