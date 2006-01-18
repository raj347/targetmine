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

import org.intermine.web.results.DisplayObject;
import org.intermine.web.results.InlineTemplateTable;

import javax.servlet.ServletContext;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.apache.log4j.Logger;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;
import org.apache.struts.tiles.ComponentContext;
import org.apache.struts.tiles.actions.TilesAction;

/**
 * Controller for an inline table created by running a template on an object details page.
 * @author Kim Rutherford
 */
public class ObjectDetailsTemplateController extends TilesAction
{
    private static final Logger LOG = Logger.getLogger(ObjectDetailsTemplateController.class);

    /**
     * @see TilesAction#execute(ComponentContext context, ActionMapping mapping, ActionForm form,
     *                          HttpServletRequest request, HttpServletResponse response) 
     */
    public ActionForward execute(ComponentContext context,
                                 ActionMapping mapping,
                                 ActionForm form,
                                 HttpServletRequest request,
                                 HttpServletResponse response)
        throws Exception {
        HttpSession session = request.getSession();
        ServletContext servletContext = session.getServletContext();

        DisplayObject displayObject = (DisplayObject) context.getAttribute("displayObject");

        if (displayObject == null) {
            return null;
        }

        TemplateQuery templateQuery = (TemplateQuery) context.getAttribute("templateQuery");        
        String templateName = templateQuery.getName();
        
        String userName = ((Profile) session.getAttribute(Constants.PROFILE)).getUsername();        
        Integer objectId = displayObject.getObject().getId();

        InlineTemplateTable itt =
            TemplateHelper.getInlineTemplateTable(servletContext, templateName,
                                                  TemplatesImportAction.ATTRIBUTE_VIEW_NAME,
                                                  objectId, userName);
        
        context.putAttribute("table", itt);
        
        return null;
    }
}