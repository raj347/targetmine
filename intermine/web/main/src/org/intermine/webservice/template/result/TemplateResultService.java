package org.intermine.webservice.template.result;

/*
 * Copyright (C) 2002-2008 FlyMine
 *
 * This code may be freely distributed and modified under the
 * terms of the GNU Lesser General Public Licence.  This should
 * be distributed with the code.  See the LICENSE file for more
 * information or http://www.gnu.org/copyleft/lesser.html.
 *
 */

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.Locale;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.struts.Globals;
import org.intermine.web.logic.template.TemplateHelper;
import org.intermine.web.logic.template.TemplateQuery;
import org.intermine.web.struts.TemplateAction;
import org.intermine.web.struts.TemplateForm;
import org.intermine.web.util.URLGenerator;
import org.intermine.webservice.core.TemplateManager;
import org.intermine.webservice.output.Output;
import org.intermine.webservice.query.result.QueryResultService;

/**
 * Web service that returns results of public template constrained with values in request. 
 * All constraints operations and values that are in template must be specified in request. 
 * @author Jakub Kulaviak
 */
public class TemplateResultService extends QueryResultService 
{

    /**
     * {@inheritDoc}}
     */
    protected void execute(HttpServletRequest request,
            HttpServletResponse response) {

        TemplateResultInput input = getInput();
        if (!validate(input)) {
            return;
        }
        
        TemplateQuery template = new TemplateManager(request).getQuery(input.getName());
        if (template == null) {
            output.addError("public template with name '" + input.getName() 
                    + "' doesn't exist.", Output.SC_NOT_FOUND);
            return;
        }
        template = new TemplateConfigurator().getConfiguredTemplate(template, 
                input.getConstraints(), getLocale(request));
        runPathQuery(template, input.getStart() - 1, input.getMaxCount(), 
                input.isComputeTotalCount(), template.getTitle(), 
                template.getDescription(), input, getMineLinkURL(request, input));
    }

    private Locale getLocale(HttpServletRequest request) {
        return (Locale) request.getSession().getAttribute(Globals.LOCALE_KEY);
    }
    
    private TemplateResultInput getInput() {
        return new TemplateResultRequestParser(request).getInput();
    }
    
    private String getMineLinkURL(HttpServletRequest request, TemplateResultInput input) {
        String ret = new URLGenerator(request).getBaseURL();
        ret += "/" + TemplateAction.TEMPLATE_ACTION_PATH; 
        ret += "?" + getQueryString(request, input);
        ret += "&" + TemplateAction.SKIP_BUILDER_PARAMETER + "&" + TemplateForm.TYPE_PARAMETER
            + "=" + TemplateHelper.ALL_TEMPLATE;
        return ret;
    }

    private String getQueryString(HttpServletRequest request,
            TemplateResultInput input) {
        String ret = "";
        ret += TemplateForm.NAME_PARAMETER + "=" + en(input.getName()) + "&";
        for (int i = 0; i < input.getConstraints().size(); i++) {
            ConstraintLoad load = input.getConstraints().get(i);
            ret += constraintToString(load, i + 1);
        }
        return ret;
    }

    private String constraintToString(ConstraintLoad load, int index) {
        String ret = "";
        ret += en("attributeOps(" + index + ")") + "=" 
            + en(load.getConstraintOp().getIndex().toString()) + "&";
        ret += en("attributeValues(" + index + ")") + "=" + en(load.getValue()) + "&";
        if (load.getExtraValue() != null) {
            ret += en("extraValues(" + index + ")") + "=" + en(load.getExtraValue()) + "&";  
        }
        return ret;
    }
    
    private String en(String value) {
        try {
            return URLEncoder.encode(value, "UTF-8");
        } catch (UnsupportedEncodingException e) {
            return "";
        }        
    }
}