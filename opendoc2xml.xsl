<!--http://pimpmyxslt.com/articles/entity-tricks-part1/-->
<!DOCTYPE xsl:stylesheet [
    <!ENTITY heading1 "text:h[@text:outline-level = '1'][not(draw:frame)]">
    <!ENTITY heading2 "text:h[@text:outline-level = '2'][not(draw:frame)]">
    <!ENTITY heading3 "text:h[@text:outline-level = '3'][not(draw:frame)]">
    ]>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
  xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
  xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
  xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
  xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0"
  xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0"
  xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0"
  xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
  exclude-result-prefixes="text dc xsl fo office style table draw xlink form script config number svg">

<xsl:output method="xml" omit-xml-declaration="no" version="1.0" encoding="utf-8" indent="yes"/>
<!-- groups of &heading2; have the same id -->
<xsl:key name="h2" match="&heading2;" use="generate-id(preceding-sibling::&heading1;[1])" />
<xsl:key name="h3" match="&heading3;" use="generate-id(preceding-sibling::&heading2;[1])" />

<xsl:key name="styles" match="/office:document/office:automatic-styles/style:style/attribute::style:parent-style-name" use="attribute::style:name" />

<xsl:strip-space elements="*"/>

  <xsl:template match="node()">
      <xsl:apply-templates select="node()"/>
  </xsl:template>

<!--

  <xsl:template match="font" />

  <xsl:template match="div">
    <xsl:apply-templates select="*"/>
  </xsl:template>
-->

<xsl:template match="/office:document/office:body/office:text">
    <temas>
        <xsl:for-each select="&heading1; | &heading2; | &heading3;" >
            <xsl:variable name="h" select="."/>
            <tema>
                <xsl:attribute name="unit">
                    <xsl:value-of select="/office:document/office:meta/dc:title" />
                </xsl:attribute>
                <filename>
                    <xsl:value-of select="concat(count(preceding-sibling::&heading1;), .)"/>
                </filename>
              <title><xsl:value-of select="." /></title>
                <nav>
                    <menu>
                        <xsl:apply-templates select="/office:document/office:body/office:text/&heading1;" mode="nav">
                            <xsl:with-param name="tema" select="$h" />
                        </xsl:apply-templates>
                    </menu>
                </nav>
                <content>
                  <xsl:apply-templates select="." mode="body"/>
                </content>
                <pie>
                  <xsl:apply-templates select="." mode="footer"/>
                </pie>
            </tema>
        </xsl:for-each>
    </temas>
</xsl:template>

<xsl:template match="&heading1; | &heading2; | &heading3;"  mode="nav">
    <xsl:param name="tema"/>
    <menu-item>
        <xsl:attribute name="active">
            <xsl:if test="generate-id($tema) = generate-id()">yes</xsl:if>
        </xsl:attribute>
        <xsl:attribute name="module">
            <xsl:value-of select="count(./preceding-sibling::&heading1;)" />
        </xsl:attribute>
        <xsl:value-of select="."/>
        <xsl:variable name="h2" select="key('h2', generate-id())" />       
        <xsl:variable name="h3" select="key('h3', generate-id())" />       
        <xsl:if test="$h2">
            <submenu>
                <xsl:apply-templates select="$h2" mode="nav">
                    <xsl:with-param name="tema" select="$tema" />
                </xsl:apply-templates>
            </submenu>
        </xsl:if>
        <xsl:if test="$h3">
            <submenu>
                <xsl:apply-templates select="$h3" mode="nav">
                    <xsl:with-param name="tema" select="$tema" />
                </xsl:apply-templates>
            </submenu>
        </xsl:if>
    </menu-item>
  </xsl:template>
  
  <xsl:template match="&heading1;" mode="body">
    <xsl:apply-templates select="following-sibling::*[preceding-sibling::&heading1;[1] = current()][not(self::&heading1;)][not(self::&heading2;)][not(preceding-sibling::&heading2;[preceding-sibling::&heading1; = current()])]" mode="paragraph" />
  </xsl:template>

   <!--matches all text beneath this &heading2; until next &heading2;.
       if there is a &heading3; in between, ignore its content
       if there is a &heading1; in between, ignore its content
       matches all that follows current &heading2; EXCEPT:
       - another h{1,2,3}
       - anything preceded by an &heading1; AND that is after the current &heading2; (i.e., it is preceded by more &heading2;s [one more exactly] than current &heading2; ) 
       - anything preceded by an &heading3; AND that is after the current &heading2; (i.e., whose NodeList of preceding &heading2;s contains current &heading2;)// doesn't work if two &heading2; have the same name

  -->
  <xsl:template match="&heading2;" mode="body">
      <xsl:apply-templates select="following-sibling::*[generate-id(preceding-sibling::&heading2;[1]) = generate-id(current())]
          [not(self::&heading1;)][not(self::&heading2;)][not(self::&heading3;)]
          [not(preceding-sibling::&heading1;[count(./preceding-sibling::&heading2;)>count(current()/preceding-sibling::&heading2;)])]
          [not(preceding-sibling::&heading3;[count(./preceding-sibling::&heading2;)>count(current()/preceding-sibling::&heading2;)])]" mode="paragraph" />
  </xsl:template>

  <xsl:template match="&heading3;" mode="body">
   <xsl:apply-templates select="following-sibling::*[preceding-sibling::&heading3;[1] = current()][not(self::&heading1;)][not(self::&heading2;)][not(self::&heading3;)][not(preceding-sibling::&heading1;[preceding-sibling::&heading3; = current()])][not(preceding-sibling::&heading2;[preceding-sibling::&heading3; = current()])]" mode="paragraph" />
  </xsl:template>

<xsl:template match="&heading1;" mode="footer">
    <xsl:variable name="prev" select="preceding-sibling::&heading1;[1][following-sibling::&heading1;[1] = current()][not(following-sibling::&heading2;[following-sibling::&heading1; = current()])][not(following-sibling::&heading3;[following-sibling::&heading1; = current()])]|preceding-sibling::&heading2;[1][following-sibling::&heading1;[1] = current()][not(following-sibling::&heading3;[following-sibling::&heading1; = current()])]" />       
    <xsl:variable name="next" select="following-sibling::&heading1;[preceding-sibling::&heading1;[1] = current()][not(preceding-sibling::&heading2;[preceding-sibling::&heading1; = current()])][not(preceding-sibling::&heading3;[preceding-sibling::&heading1; = current()])]|following-sibling::&heading2;[1][preceding-sibling::&heading1;[1] = current()][not(preceding-sibling::&heading3;[preceding-sibling::&heading1; = current()])][not(preceding-sibling::&heading1;[preceding-sibling::&heading1; = current()])]" /> 
    <xsl:if test="$prev">
        <prev>
            <xsl:attribute name="module">
                <xsl:value-of select="count($prev/preceding-sibling::&heading1;)" />
            </xsl:attribute>
            <xsl:value-of select="$prev" />
        </prev>
    </xsl:if>
    <xsl:if test="$next">
        <next>
            <xsl:attribute name="module">
                <xsl:value-of select="count($next/preceding-sibling::&heading1;)" />
            </xsl:attribute>
            <xsl:value-of select="$next" />
        </next>
    </xsl:if>
</xsl:template>

<xsl:template match="&heading2;" mode="footer">
    <!--<xsl:variable name="prev" select="preceding-sibling::&heading1;[1][following-sibling::&heading2;[1] = current()][not(following-sibling::&heading1;[following-sibling::&heading2; = current()])][not(following-sibling::&heading3;[following-sibling::&heading2; = current()])]|preceding-sibling::&heading2;[1][following-sibling::&heading2;[1] = current()][not(following-sibling::&heading3;[following-sibling::&heading2; = current()])]
        |
        preceding-sibling::&heading3;[1][following-sibling::&heading2;[1] = current()]" 
        />   -->
        <!-- inmediately preceeding header (h) ?
             &heading1;[1] IF that &heading1;'s first child is = current
             &heading2;[1] IF both have the same parent AND &heading2;[1] has no children (i.e., inmediately preceding &heading3; has &heading2;[1] for parent) 
             &heading3;[1] IF 
         -->
    <xsl:variable name="prev" select="
        preceding-sibling::&heading2;[1][preceding-sibling::&heading1;[1] = current()/preceding-sibling::&heading1;[1]]
            [not(preceding-sibling::&heading3;[1][generate-id(preceding-sibling::&heading2;[1]) = generate-id(current())])]
        |
        preceding-sibling::&heading1;[1][following-sibling::&heading2;[1] = current()]
        "/>   
    <!-- 
        Old xpath that does not work and that i don't understand
        following-sibling::&heading1;[1][preceding-sibling::&heading2;[1] = current()][not(preceding-sibling::&heading1;[preceding-sibling::&heading2; = current()])][not(preceding-sibling::&heading3;[preceding-sibling::&heading2; = current()])]|following-sibling::&heading2;[1][preceding-sibling::&heading2;[1] = current()][not(preceding-sibling::&heading3;[preceding-sibling::&heading2; = current()])]
    -->
    <xsl:variable name="next" select="
        following-sibling::&heading1;[1][preceding-sibling::&heading2;[1] = current()][not(preceding-sibling::&heading3;[preceding-sibling::&heading2;[1] = current()])]
        |
        following-sibling::&heading2;[1][preceding-sibling::&heading1;[1] = current()/preceding-sibling::&heading1;[1]][not(preceding-sibling::&heading3;[preceding-sibling::&heading2;[1] = current()])]
        |
        following-sibling::&heading3;[1][preceding-sibling::&heading2;[1] = current()]" /> 
    <xsl:if test="$prev">
        <prev>
            <xsl:attribute name="module">
                <xsl:value-of select="count($prev/preceding-sibling::&heading1;)" />
            </xsl:attribute>
            <xsl:value-of select="$prev" />
        </prev>
    </xsl:if>
    <xsl:if test="$next">
        <next>
            <xsl:attribute name="module">
                <xsl:value-of select="count($next/preceding-sibling::&heading1;)" />
            </xsl:attribute>
            <xsl:value-of select="$next" />
        </next>
    </xsl:if>
</xsl:template>

<xsl:template match="&heading3;" mode="footer">
    <xsl:variable name="prev" select="
        preceding-sibling::&heading2;[1][following-sibling::&heading3;[1] = current()]
        |
        preceding-sibling::&heading3;[1][preceding-sibling::&heading2;[1] = current()/preceding-sibling::&heading2;[1]]
        "/>   

    <!-- 'next' logic
       DETECT IF FOLLOWED BY 
           SAME LEVEL: both have the same parent 
           INFERIOR LEVEL: if it is his parent (i.e if the inmediately preceeding superior is the current node)
           SUPERIOR LEVEL: if it is preceded by current AND there are no &heading3; in between (i.e. the first ocurrence of &heading3; is NOT preceded first by current)
     -->

    <xsl:variable name="next" select="
        following-sibling::&heading3;[1][preceding-sibling::&heading2;[1] = current()/preceding-sibling::&heading2;[1]]
        |
        following-sibling::&heading2;[1][preceding-sibling::&heading3;[1] = current()]
        "/> 
    <xsl:if test="$prev">
        <prev>
            <xsl:attribute name="module">
                <xsl:value-of select="count($prev/preceding-sibling::&heading1;)" />
            </xsl:attribute>
            <xsl:value-of select="$prev" />
        </prev>
    </xsl:if>
    <xsl:if test="$next">
        <next>
            <xsl:attribute name="module">
                <xsl:value-of select="count($next/preceding-sibling::&heading1;)" />
            </xsl:attribute>
            <xsl:value-of select="$next" />
        </next>
    </xsl:if>
</xsl:template>

<!-- HTML COMPONENTS -->

<xsl:template match="text:p[not(@text:style-name = 'P1') and not(draw:frame)]" mode="paragraph" priority="1">
    <xsl:variable name="attribute" select="@text:style-name"/>
    <p>
        <xsl:attribute name="class">
            <xsl:value-of select="$attribute"/>
        </xsl:attribute>
        <xsl:apply-templates mode="character" />
    </p>
</xsl:template>

<xsl:template match="text:h[@text:outline-level='4']" mode="paragraph">
    <h4><xsl:value-of select="." /></h4>
</xsl:template>

<xsl:template match="text:span[@text:style-name = 'Emphasis']" mode="character">
    <b>
        <xsl:value-of select="." />
    </b>
</xsl:template>

<xsl:template match="text:p[not(ancestor::table:table) and not(draw:frame)]" mode="paragraph">
    <p>
        <xsl:apply-templates mode="character" />
    </p>
</xsl:template>

<xsl:template match="text:p[draw:frame]" mode="paragraph" priority="2">
    <xsl:apply-templates select="draw:frame" mode="image" />
</xsl:template>

<xsl:template match="draw:frame[not(draw:text-box)]" mode="image">
    <xsl:variable name="base64" select="draw:image/office:binary-data"/>
    <img>
        <xsl:attribute name="src">
            <xsl:value-of select="concat('data:;base64,', $base64)"/>
        </xsl:attribute>
    </img>
</xsl:template>

<xsl:template match="draw:frame[draw:text-box]" mode="image">
    <xsl:variable name="base64" select="draw:text-box/text:p/draw:frame/draw:image/office:binary-data"/>
    <div class="figure">
        <p>
            <img class="fg-scaled">
                <xsl:attribute name="src">
                    <xsl:value-of select="concat('data:;base64,', $base64)"/>
                </xsl:attribute>
            </img>
        </p>
        <p>
            <xsl:value-of select="draw:text-box/text:p/text()[1]"/>
            <xsl:value-of select="draw:text-box/text:p/text:sequence" />
            <xsl:value-of select="draw:text-box/text:p/text()[2]"/>
        </p>
    </div>
</xsl:template>

<xsl:template match="text:p[@text:style-name='ejemplo']" mode="paragraph" priority="3">
    <div class="ejemplo">
        <p>
            <xsl:value-of select="."/>
        </p>
    </div>
</xsl:template>

<xsl:template match="text:p[@text:style-name='articulate']" mode="paragraph" priority="3">
    <iframe width="100%" height="546" frameBorder="0">
        <xsl:attribute name="src">
            <xsl:value-of select="concat('articulates/', string(.), '/story.html')" />
        </xsl:attribute>
        Su navegador no es compatible. Por favor, descargue un navegador más reciente. 
    </iframe>
</xsl:template>

<xsl:template match="text:p[@text:style-name='pullquote']" mode="paragraph" priority="2">
    <div class='alert'>
        <img src="img/png/warning.png" />
        <p>
            <xsl:apply-templates mode="character" />
        </p>
    </div>
</xsl:template>

<xsl:template match="text:p[@text:style-name='globo']" mode="paragraph" priority="2">
    <div class='globe'>
        <p>
            <xsl:apply-templates mode="character" />
        </p>
        <div class="triangle"><xsl:comment/></div>
    </div>
</xsl:template>

<xsl:template match="text:p[@text:style-name='Quotations']" mode="paragraph" priority="2">
    <blockquote class="blockquote">
        <p>
            <xsl:apply-templates mode="character"/>
        </p>
    </blockquote>
    <div class="clearfix"><xsl:comment/></div>
</xsl:template>

<xsl:template match="text:p[@text:style-name='engage']" mode="paragraph" priority="3">
    <iframe width="100%" height="546" frameBorder="0">
        <xsl:attribute name="src">
            <xsl:value-of select="concat('articulates/', string(.), '/interaction.html')" />
        </xsl:attribute>
        Su navegador no es compatible. Por favor, descargue un navegador más reciente. 
    </iframe>
</xsl:template>

<xsl:template match="table:table" mode="paragraph">
    <table>
        <xsl:apply-templates select="table:table-row" />
    </table>
</xsl:template>

<xsl:template match="table:table[substring(@table:style-name,1,3) = 'faq']" mode="paragraph" priority="1">
    <div class="accordion">
        <xsl:apply-templates select="table:table-row" mode="faq" />
    </div>
</xsl:template>

<xsl:template match="table:table-row" mode="faq" priority="1">
    <details>
        <summary>
            <xsl:value-of select="table:table-cell[1]" />
        </summary>
        <xsl:apply-templates select="table:table-cell[2]/*" mode="paragraph" />
    </details>
</xsl:template>

<xsl:template match="table:table[@table:style-name = 'porcentaje']" mode="paragraph" priority="1">
    <xsl:variable name="n" select="count(table:table-row)" />
    <xsl:variable name="W">400</xsl:variable>
    <xsl:variable name="H">400</xsl:variable>
    <xsl:variable name="w" select="($W div $n) * (3 div 4)"/>
    <xsl:variable name="m" select="($W - $n * $w) div ($n + 1)" />
    <svg width="{concat($W, 'px')}" height="{concat($H, 'px')}">
        <g>
            <!--<xsl:apply-templates select="table:table-row[not(generate-id(current()) = generate-id(parent::table:table/table:table-row[1]))]" mode="percentage">-->
            <xsl:apply-templates select="table:table-row" mode="percentage">
                <xsl:with-param name="H" select="$H" />
                <xsl:with-param name="w" select="$w" />
                <xsl:with-param name="m" select="$m" />
            </xsl:apply-templates>
        <line x1="{$m div 2}" y1="{$H - 15}" x2="{$W - $m div 2}" y2="{$H - 15}" stroke="silver" stroke-width="1"/>
        <line x1="{$m div 2}" y1="{$H - 15}" x2="{$m div 2}" y2="15" stroke="silver" stroke-width="1"/>
        </g>
    </svg>
</xsl:template>

<xsl:template match="table:table-row" mode="percentage">
    <xsl:param name="H" />
    <xsl:param name="w" />
    <xsl:param name="m" />
    <xsl:variable name="dividend"><xsl:value-of select="table:table-cell[2]" /></xsl:variable>
    <xsl:variable name="pos" select="count(preceding-sibling::table:table-row)" />
    <xsl:variable name="x" select="$m * ($pos + 1) + $w * $pos" />
    <xsl:variable name="h" select="$H * ($dividend div 100)"/>
    <!--margin-y is hardcoded -->
    <xsl:variable name="my" select="15"/>
    <xsl:variable name="y" select="$H - $my - $h"/>
    <xsl:message><xsl:value-of select="$x" /></xsl:message>
    <xsl:variable name="text" select="table:table-cell[1]" />

    <text x="{$x + floor($w div 2)}" y="{$H - $h - $my - 15}" style="text-anchor:middle;font-size:10px;"><xsl:value-of select="concat($dividend, '%')" /></text>

    <rect x="{$x}" y="{$y}" style="fill:steelblue" width="{$w}" height="{$h}">
    </rect> 
    <text x="{$x + floor($w div 2)}" y="{$H - floor($my div 3)}" style="text-anchor:middle;font-size:10px;">
        <xsl:value-of select="$text" />
    </text>
</xsl:template>

<xsl:template match="table:table-row">
    <tr>
        <xsl:apply-templates select="table:table-cell" />
    </tr> 
</xsl:template>

<xsl:template match="table:table-cell">
    <td>
        <xsl:if test="./attribute::table:number-columns-spanned">
            <xsl:attribute name="colspan">
                <xsl:value-of select="./attribute::table:number-columns-spanned" />
            </xsl:attribute>
        </xsl:if>

        <!-- <xsl:apply-templates select="*" mode="character" /> -->
        <xsl:value-of select="." />
    </td> 
</xsl:template>

<xsl:template match="text:list" mode="paragraph">
    <ul>
        <xsl:apply-templates select="text:list-item" />
    </ul>
</xsl:template>

<xsl:template match="text:list-item">
    <li>
        <xsl:apply-templates select="text:p" mode="paragraph" />
    </li>
</xsl:template>

<xsl:template match="text:note" mode="character">
    <cite class="tooltip">
        <xsl:value-of select="text:note-body" />
    </cite>
</xsl:template>

<xsl:template match="text:a" mode="character">
    <a>
        <xsl:attribute name="href">
            <xsl:value-of select="attribute::xlink:href" />
        </xsl:attribute>
        <xsl:value-of select="." />
    </a>
</xsl:template>

</xsl:stylesheet>
