package org.intermine.web;

/*
 * Copyright (C) 2002-2005 FlyMine
 *
 * This code may be freely distributed and modified under the
 * terms of the GNU Lesser General Public Licence.  This should
 * be distributed with the code.  See the LICENSE file for more
 * information or http://www.gnu.org/copyleft/lesser.html.
 *
 */

import junit.framework.TestCase;

/**
 * Tests for the WebUtil class.
 *
 * @author Kim Rutherford
 */

public class WebUtilTest extends TestCase
{
    public WebUtilTest (String arg) {
        super(arg);
    }
    
    public void testWildcardSqlToUser() throws Exception {
        String value = WebUtil.wildcardSqlToUser("a");
        assertEquals("wildcardSqlToUser(a)", "a", value);
        
        value = WebUtil.wildcardSqlToUser("a%");
        assertEquals("wildcardSqlToUser(a%)", "a*", value);
        
        value = WebUtil.wildcardSqlToUser("%a");
        assertEquals("wildcardSqlToUser(%a)", "*a", value);

        value = WebUtil.wildcardSqlToUser("\\%a");
        assertEquals("wildcardSqlToUser(\\%a)", "%a", value);

        value = WebUtil.wildcardSqlToUser("_a");
        assertEquals("wildcardSqlToUser(_a)", "?a", value);

        value = WebUtil.wildcardSqlToUser("\\_a");
        assertEquals("wildcardSqlToUser(\\_a)", "_a", value);

        value = WebUtil.wildcardSqlToUser("?a");
        assertEquals("wildcardSqlToUser(?a)", "\\?a", value);

        value = WebUtil.wildcardSqlToUser("*a");
        assertEquals("wildcardSqlToUser(*a)", "\\*a", value);

        value = WebUtil.wildcardSqlToUser("\\?a");
        assertEquals("wildcardSqlToUser(\\?a)", "\\\\\\?a", value);

        value = WebUtil.wildcardSqlToUser("\\*a");
        assertEquals("wildcardSqlToUser(\\*a)", "\\\\\\*a", value);

        value = WebUtil.wildcardSqlToUser("*?%_\\*\\?\\%\\_");
        assertEquals("wildcardSqlToUser(*?%_\\*\\?\\%\\_)", "\\*\\?*?\\\\\\*\\\\\\?%_", value);
    }


    public void testWildcardUserToSql() throws Exception {
        String value = WebUtil.wildcardUserToSql("a");
        assertEquals("wildcardUserToSql(a)", "a", value);
        
        value = WebUtil.wildcardUserToSql("a*");
        assertEquals("wildcardUserToSql(a*)", "a%", value);
        
        value = WebUtil.wildcardUserToSql("*a");
        assertEquals("wildcardUserToSql(*a)", "%a", value);

        value = WebUtil.wildcardUserToSql("\\*a");
        assertEquals("wildcardUserToSql(\\*a)", "*a", value);

        value = WebUtil.wildcardUserToSql("?a");
        assertEquals("wildcardUserToSql(?a)", "_a", value);

        value = WebUtil.wildcardUserToSql("\\?a");
        assertEquals("wildcardUserToSql(\\?a)", "?a", value);

        value = WebUtil.wildcardUserToSql("_a");
        assertEquals("wildcardSqlToUser(_a)", "\\_a", value);

        value = WebUtil.wildcardUserToSql("%a");
        assertEquals("wildcardSqlToUser(%a)", "\\%a", value);

        value = WebUtil.wildcardUserToSql("\\_a");
        assertEquals("wildcardUserToSql(\\_a)", "\\\\\\_a", value);

        value = WebUtil.wildcardUserToSql("\\%a");
        assertEquals("wildcardUserToSql(\\%a)", "\\\\\\%a", value);

        value = WebUtil.wildcardUserToSql("*?%_\\*\\?\\%\\_");
        assertEquals("wildcardUserToSql(*?%_\\*\\?\\%\\_)", "%_\\%\\_*?\\\\\\%\\\\\\_", value);
    }
}
