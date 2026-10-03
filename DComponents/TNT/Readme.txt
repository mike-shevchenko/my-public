  ** Tnt Delphi UNICODE Controls Project **

Website: http://home.ccci.org/wolbrink/tntmpd/delphi_unicode_controls_project.htm
Email: wolbrink@ccci.org

These controls are provided as-is, with no implied warranty.  They are freely available for you to use in your own projects.  Please let me know if you have found them helpful.  Also, please let me know if you find any bugs or other areas of needed improvement.

---Background----------------------------

Designing software for an international audience, I've always wanted to write a full UNICODE application.  My approach so far, has been to write Unicode on the inside, and MBCS on the outside.  This has always been frustrating, because (even on Windows NT/2000/XP which provide native Unicode window controls) the WideStrings inside my application and databases were always confined to an ANSI VCL.  And, since the VCL was designed to wrap the low-level Windows details, why shouldn't the VCL hide the fact that sometimes native Unicode controls are not possible on the given version of Windows.  I believe the VCL should be written with a Unicode interface, even if it must (at times) deal with an ANSI operating system.  For example, TEdit should expose Text as a WideString, even if it has to convert the WideString to an AnsiString on the Windows 9X platform.

In the past, the ANSI VCL may have made a little sense, considering that there were many more users of Windows 9X, than Windows NT.  There would have been some performance penalty to use WideStrings on the Windows 9X platform.  But with the faster computers of today, and with more people using platforms such as Windows 2000 and Windows XP, the ANSI VCL just doesn't make sense anymore.  In fact, having to use the the ANSI VCL on Windows NT/2000/XP is slower because of the constant conversion to and from UNICODE inside Windows.

My coding signature is Tnt.  I will use this to denote my classes from others.

For more information about me: <http://home.ccci.org/wolbrink/index.htm>
Some of my software projects (all written in Delphi).   
    TntMPD (contact manager for missionaries)     <http://home.ccci.org/wolbrink/tntmpd/index.htm>
    Jesus Film Screen Saver                               <http://home.ccci.org/wolbrink/screensaver.htm>
    ActiveX SCR control                                     <http://home.ccci.org/wolbrink/TntBin/ActiveXSCR.exe>

---Design Goals----------------------------

I want the controls to work on Windows 95, 98, ME, NT, 2000, XP, etc.  I want a single EXE for all platforms.  Of course, full UNICODE support is only truly available on NT/2000/XP.  In other words, the controls should automatically scale to take advantage of native Unicode support when possible.

I want the controls to inherit from the Delphi VCL.  I want to reuse as much code as possible.  For the most part this makes sense.  The only sticky part is where text messages get passed around.  But I believe I've gotten past this through strategic subclassing at various points in the message flow chain.  To give a rough comparison of why this is so important, check out the following chart which compares the lines of code in the VCL for a given control (4,397 in all), and the lines of code required in my descendent controls (655 in all).  Besides saving lines of code, I get the advantage of automatically inheriting new features as new versions of Delphi come out.  One such example is the AlphaBlending feature in the Delphi 6 TForm.  Even though I use Delphi 5 now, I won't have to add any code to get this new feature. 

---More Interesting Information----------------------------
Case Study: Porting an MFC Application to Unicode:  It looks like the FrontPage 2002 team did the roughly the same thing to MFC as what I'm doing to the VCL.  They did this with the same goal in mind: to support Unicode as much as possible depending on the support offered by Windows.  Another goal was "Don’t abandon MFC; don’t rewrite app".  Because they still want to support Windows 9X using the same worldwide EXE used everywhere.  They couldn't just compile with the _UNICODE directive.  They had to start with the ANSI MFC, strategically subclassing window procedures at just the right places.  Hmmm... sounds familiar.