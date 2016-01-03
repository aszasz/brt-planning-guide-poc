package format;

import format.Document;
using StringTools;


class ToParseString {

	var content:String;
	var curpos:Int;
    public var last:String; //last peek or read result
    var posafterlastpeek:Int; 
	var curline:Int;
    var curlineStartPos:Int;

    public function new (s:String, ?curline=1,?curlineStartPos=0)
    {
        content = s;
        curpos = 0;
        posafterlastpeek = curpos;
        lastpeek=""
    }

    public function peek(?offset=0, ?len=1) 
    {
        if (len<1) throw ('peek with len<1')
        var readpos = curpos + offset;
        posafterlastpeek = readpos + len; 
        var lastpos = posafterlastpeek - 1;
        lastpeek = null
        if (readpos < 0) return null;
        if (lastpos > s.length) return null;
        lastpeek = content.substr(readpos, len);
        return lastpeek;
        
    }

    public function read(?offset=0, ?len=1){
        var ret = peek(offset,len);
        curpos = posafterlastpeek;
        return ret;
    }
		
    function peakUntil(end:String,?include=false) {
		var i = content.indexOf(end,curpos);
        if (i == -1) return null;
        return  substring (curpos, i + end.length) ;
    }

    function readUntil(end:String) {
		var i = content.indexOf(end,curpos);
        if (i == -1) return null;
        ret =  substring (curpos, i + end.length) ;
        curpos = i + end.length;
    }

    function readUntilPattern(whatpat:Array<String>)
    {
        if (whatpat.length == 0) return null;
        var tomatch = whatpat.join("|");
        var pat = new EReg ('($tomatch)',"s");
        if (pat.match(s)) {
//            trace ('\n-- left= ${pat.matchedLeft()}');
//            trace ('\n-- match= ${pat.matched(1)}');
//            trace ('\n-- right= ${pat.matchedRight()}');
//            trace ('\n--Pos = ${pat.matchedPos()}');
            return pat.matched(0);
        } else{
            trace ("no match");
            return null;
        }
    }

    function markNewLine()
        curline = curline + 1;
        curlineStartPos = curpos
    }
    
    function getPos() {
        return { line : curline, 
                 linestart: curlineStartPos,
                 pos: curpos - curlineStartPos 
               };
    }

    function setPos({line:Int, linestart:Int, pos: Int})
    {
        curline = line;
        curlineStartPos = linestart;
        pos = linestart + por;
    }


