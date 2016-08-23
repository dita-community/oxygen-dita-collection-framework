# DITA Collections Oxygen Framework
OxygenXML framework for making Saxon collections from DITA maps to make it easy to operate on the files in a map using XQuery.

When added to Oxygen's frameworks directory, allows you to treat a DITA map
as the source of an XPath collection() using Saxon through OxygenXML.

## Installation

The framework is available as an Oxygen add-on through the Oxygen add-on manager.

To install the add-on initially do the folowing:

1. Go to Preferences->Add-ons
2. Add a new item with the URL "https://raw.githubusercontent.com/dita-community/oxygen-dita-collection-framework/master/updateSite.xml"
3. Click "OK" to save the setting.
4. Go to Help->Install new updates
5. From the "Show add-ons from" dropdown either choose "ALL AVAILABLE SITES" or choose the oxygen-dita-collection-framework site you just added.
6. After a bit you should see the Oxygen DITA Collection Framework in the list of available add ons. Select it and click "Next"
7. Check the box to accept the license agreement and click "Install" to start the installation process.
8. You should get a pop-up indicating that the add-on is not signed. It is not. Click OK to accept the add-on anyway. The framework does not
have any compiled files so it's pretty safe.
9. Restart Oxygen. 

If you select "Enable automatic updates checking" in the Preferences->Add-ons panel, then when the framework is updated you will get
the update automatically.

## Usage

With a DITA map open in the main editor (not the Map Manager) construct a collection
like so in the Oxygen XPath/XQuery Builder view:

```
let $docs := collection('ditaTopics:/' || document-uri(.))

return 
<result>{
for $doc in $docs 
return <doc uri="{document-uri($doc)}"/>
}</result>  
```

## How It Works

The framework uses Oxygens "convert:" framework, which handles URIs starting with "convert:" to do on-the-fly conversion of data. This can be used, for example, to treat non-XML formats as XML simply by refering to a "convert:" URI with the appropriate configuration.

In this case, the conversion is from a DITA map to a Saxon collection XML document.

The framework includes an XSLT transform, ditamap2saxon-collection.xsl, that runs against the map document open in the editor when you run your XQuery or XPath. The XSLT transform processes the root map and all submaps to find all topicrefs that point to topics. It then creates a Saxon collection XML document that lists each map and topic, including the initial root map, e.g.:

```
<collection stable="true">
   <!-- Specify the files for this collection. -->
   <!-- It contains one or more entries of the form: -->
    <doc href="path/to/file.xml"/>

</collection>
```

The framework includes an XML entity resolution catalog that maps URIs starting with "ditaTopics:" into "convert:" URLs with the appropriate configuration parameters that point to the XSLT provided by the framework. (You could specify the convert: URI directly but this approach makes the URI easier to define and protects against changes in the underlying implementation details provided in the framework.)

By default the XSLT transform only includes normal-role topics, but you can tell it to also include resource-only topics using includeResourceOnly runtime parameter.

## Taking it further

If you look a the framework contents you can see that it's not that complicated. It wouldn't be hard to extend this code to work with other types of XML formats or to use different business logic in constructing the Saxon collection.

## More XQueries

The DITA Community dita-utilities project includes some XQuery scripts that use the DITA collections framework:

* Key usage report: https://github.com/dita-community/dita-utilities/tree/master/src/xquery/key-usage-report

You can cut and paste the XQuery code into the Oxygen XPath/XQuery Builder. It produces a report of all the keys used for keyrefs (not conkeyrefs) and other details to help with debugging key-related issues.


