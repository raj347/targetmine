package org.intermine.modelproduction.uml;

/*
 * Copyright (C) 2002-2004 FlyMine
 *
 * This code may be freely distributed and modified under the
 * terms of the GNU Lesser General Public Licence.  This should
 * be distributed with the code.  See the LICENSE file for more
 * information or http://www.gnu.org/copyleft/lesser.html.
 *
 */

import java.io.InputStream;
import java.io.Reader;
import java.io.InputStreamReader;

import org.intermine.modelproduction.ModelParser;
import org.intermine.modelproduction.xml.InterMineModelParser;
import org.intermine.metadata.AttributeDescriptor;
import org.intermine.metadata.ReferenceDescriptor;
import org.intermine.metadata.CollectionDescriptor;
import org.intermine.metadata.ClassDescriptor;
import org.intermine.metadata.Model;

import junit.framework.TestCase;

public class XmiParserFunctionalTest extends TestCase
{
    private static final String MODEL = "xmitest";
    private static final String PKG = "org.intermine.model." + MODEL;
    private static final String NS = "http://www.intermine.org/model";

    public XmiParserFunctionalTest(String arg) {
        super(arg);
    }

    public void testProcess() throws Exception {
        // expected
        ModelParser parser1 = new InterMineModelParser();
        Reader reader1 = new InputStreamReader(getClass().getClassLoader().getResourceAsStream(MODEL + ".xml"));
        Model model1 = parser1.process(reader1);
        // actual
        ModelParser parser2 = new XmiParser(MODEL, PKG, NS);
        Reader reader2 = new InputStreamReader(getClass().getClassLoader().getResourceAsStream(MODEL + ".xmi"));
        Model model2 = parser2.process(reader2);
        assertEquals(model1, model2);
    }

}

