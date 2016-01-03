package format;

import format.Document;

using format.ExprTools;
using StringTools;


typedef InputBuffer = {
	filename:String,
	basepath:String,
	content:String,
	curpos:Int,
	curline:Int,
    curlineStartPos:Int
}

class Parser {

    var label:Null<String>;
    var input:Array<InputBuffer>;
    public var curpos (get, set):Int;
    public var curline (get, set):Int;
    
    public function filename() { 
        if (input.length>0) return input[input.length].filename;
        return null;
    }

    public function basepath() { 
        if (input.length>0) return input[input.length].basepath;
        return null;
    }

    public function get_curpos() { 
       if (input.length>0)  return input[input.length].pos; 
       return null;
    }

    public function get_curline() { 
        if (input.length>0) return input[input.length].curline;
        return null;
    }
    
    public function set_curline (newline) { 
        input[input.length].curline = newline; 
        input[input.length].curlinetartpos = input[input.length].curpos; 
    }

    public function set_curpos(newpos:Int) {
        left = newpos - input[input.length].content.length; 
        if (left>0) {
            input.pop;
            this.curpos += left;
        }
    }
    
    function mkPos() {
        if (input.length>0)
            return { file : input[input.length].fname, 
                     line : input[input.length].curline,
                     pos: input[input.length].curpos - input[input.length].curlinestartpos };
        else
            return null;
    }

    function printBufferPosition (ib:InputBuffer) {
        return 'file = ${ib.filename}, line = ${ib.curline}, pos = ${ib.curpos - ib.curlinestartpos}'
    }
    
    function printStack() {
        if (input.length == 0) return 'no file on input stack';
        var ret = input[0].basepath; 
        for (inputbuffer in input) ret i+= "--> " printBufferPosition (inputbuffer); 
    }

    function addInputBuffer (relativeFilePath:String, ?basePath:String, ?content=String)
    {
        if (basePath == null) basePath = basepath();
        var path = basePath + "/" + relativeFilePath
        var filePathSplit = relativeFilePath.split("/");
        var fileName = filePathSplit.pop();
        var fileDir = filePathSplit.join("/");
        if (content == null) {
            var prevWorkDir = Sys.getCwd();
            if (fileDir != "") Sys.setCwd(fileDir);
            if (!FileSystem.exists(path)) throw (mkErr('file not found: $path'));
            content = sys.io.File.getContent(path).rtrim;
            Sys.setCwd(prevWorkDir);
        }
        inputbuffer = {
            filename : fileName,
            basepath : fileDir,
            content : content,
            curpos : 0,
            curline : 1,
            curlineStartPos : 0
        };
        input.push(inputBuffer);
    }
    function peek(?offset=0, ?len=1) 
    {
        var readpos = input[input.length].pos + offset;
        var lastpos = readpos + len - 1;
        if (readpos > input[input.length].buf.length){
            var newoffset =  readpos - input[input.length].buf.length;
            var temp = input.pop();
            var ret =  peek(newoffset, len);
            input.push(temp);
            return ret;
        }
        if (lastpos > input[input.length].buf.length){
            var ret = input[input.length].buf.substr(readpos);
            var newlen = len - ret.length;
            var newoffset = 0;
            var temp = input.pop();
            ret +=  peek(newoffset, newlen);
            input.push(temp);
            return ret;
        }
        return input[input.length].buf.substr(readpos, len);
    }

}


	function mkExpr<Def>(expr:Def, ?pos:Pos)
		return { expr : expr, pos : pos != null ? pos : mkPos() };

	function mkErr(msg:String, ?pos:Pos)
		return { msg : msg, pos : pos != null ? pos : mkPos() };

	function parseFancyLabel()
	{
		if (peek(0, 3) != ":::")
			return null;
		var pos = mkPos();
		input.pos += 3;
		while (peek().isSpace(0))
			input.pos++;
		var buf = new StringBuf();
		while (true) {
			switch (peek()) {
			case null:
				break;
			case c if (~/[a-z0-9-]/.match(c)):
				input.pos++;
				buf.add(c);
			case c if (c.isSpace(0)):
				break;
			case inv:
				throw mkErr('Invalid char for label: $inv', pos);
			}
		}
		return buf.toString();
	}

	// inline code isn't parsed at all
	function parseInlineCode():Expr<HDef>
	{
		if (peek() != "`")
			return null;
		input.pos++;
		var pos = mkPos();
		var buf = new StringBuf();
		while (true) {
			switch peek() {
			case null:
				throw mkErr("Unclosed inline code expression", pos);
			case "\n":
				if (StringTools.trim(buf.toString()) == "")
					throw mkErr("Paragraph breaks are not allowed in inline code expression", pos);
				input.pos++;
				input.lino++;
				buf.add(" ");
			case "`":
				input.pos++;
				break;
			case c:
				input.pos++;
				buf.add(c);
			}
		}
		return mkExpr(HCode(buf.toString()));
	}

	function parseHorizontal(delimiter:Null<String>, ltrim=false):Expr<HDef>
	{
		var pos = mkPos();
		var buf = new StringBuf();
		function readChar(c) {
			ltrim = false;
			input.pos++;
			buf.add(c);
		}
		function readUntil(end) {
			var i = input.buf.indexOf(end, input.pos);
			var ret = i > -1 ? input.buf.substring(input.pos, i + end.length) : input.buf.substring(input.pos);
			input.pos += ret.length;
			return ret;
		}
		while (true) {
			switch peek() {
			case null:
				break;
			case "/" if (peek(1) == "/"):
				readUntil("\n");
			case "/" if (peek(1) == "*"):
				var p = mkPos();
				readUntil("*/");
				if (input.buf.substr(input.pos - 2, 2) != "*/")
					throw mkErr("Unclosed comment", p);
			case "\r":
				input.pos++;
			case " ", "\t":
				input.pos++;
				if (!ltrim && peek(0) != null && !peek(0).isSpace(0))
					buf.add(" ");
			case "\n":
				input.pos++;
				input.lino++;
				if (StringTools.trim(buf.toString()) == "")
					return null;
				if (peek(0) != null && !peek(0).isSpace(0))
					buf.add(" ");
				break;
			case ":" if (peek(1, 2) == "::"):
				var pos = mkPos();
				var lb = parseFancyLabel();
				if (lb == null) {
					readChar(":");
					break;
				}
				if (label != null)
					throw mkErr("Cannot set more than one label to the same vertical element", pos);
				label = lb;
			case "`":
				if (buf.toString().length > 0)
					break;  // finish the current expr
				return parseInlineCode();
			case _ if (delimiter != null && peek(0, delimiter.length) == delimiter):
				input.pos += delimiter.length;
                trace ('I found a $delimiter');
				delimiter = null;
				break;
			case "*":
				if (buf.toString().length > 0)
					break;  // finish the current expr
				delimiter = peek(1) == "*" ? "**" : "*";
				input.pos += delimiter.length;
				return mkExpr(HEmph(parseHorizontal(delimiter, ltrim)), pos);
			case c:
				readChar(c);
			}
		}
		var text = buf.toString();
		return text.length != 0 ? mkExpr(HText(buf.toString()), pos) : null;
	}

	function parseFancyHeading(curDepth:Int)
	{
		var rewind = {
			pos : input.pos,
			lino : input.lino
		};

		var pat = ~/^(#+)(\*)?([^#]|(\\#))*?\n/;  // FIXME what it the input ends without a trailing newline?
		if (!pat.match(input.buf.substr(input.pos)))
			return null;
		var pos = mkPos();

		var depth = pat.matched(1).length;
		if (depth > 6)
			throw mkErr("Heading level must be in the range from 1 to 6", pos);

		// don't advance the input or finish parsing if we would need to rewind to close some sections
		if (depth <= curDepth)
			return { depth : depth, label : null, name : null, pos : pos };

		input.pos += depth;

		if (pat.matched(2) == "*") {
			trace("TODO unnumbered section; don't know what to do with this yet");
			input.pos++;
		}

		var name = [];
		label = null;
		while (true) {
			var h = parseHorizontal(null, true);
			if (h == null)
				break;
			name.push(h);
		}
		var nameExpr = switch name.length {
		case 0: throw mkErr("A heading requires a title", pos);
		case 1: name[0];
		case _: mkExpr(HList(name), name[0].pos);
		}

		if (label == null)
			label = nameExpr.toLabel();

		return { depth : depth, label : label, name : nameExpr, pos: pos };
	}

    function parseTable 
    {
        var pat = ~/^#TAB#(.+)\n\|(    /
        var name = [];
		label = null;
		while (true) {
			var h = parseHorizontal("\n|", true);
			if (h == null)
				break;
			name.push(h);
		}
		var nameExpr = switch name.length {
		case 0: throw mkErr("A table a title", pos);
		case 1: name[0];
		case _: mkExpr(HList(name), name[0].pos);
		}

		if (label == null)
			label = nameExpr.toLabel();

        return { title:name, table:table, label:nameExpr, pos:pos};
    }

	function parseVertical(depth:Int):Expr<VDef>
	{
		var list = [];
		while (true) {
			switch peek() {
			case null:
				break;
			case "\n":
				input.pos++;
				input.lino++;
            case "#" if peek(0,4) = "#TAB#"
                var table = parseTable()
                if (table == null) 
                    throw mkErr('Fail to read table');
                else
                    list.push(mkExpr(VTable(table.title, table.table, table.label), table.pos));
			case "#": // fancy
				var heading = parseFancyHeading(depth);
				if (heading != null) {
					if (heading.depth <= depth) {
						// must close the previous section first
						break;
					} else if (heading.depth == depth + 1) {
						list.push(mkExpr(VSection(heading.name, parseVertical(heading.depth), heading.label), heading.pos));
					} else {
						throw mkErr('Cannot increment hierarchy depth from $depth to ${heading.depth}; step larger than 1', heading.pos);
					}
				} else {
					trace('TODO handle other fancy features at ${mkPos()}');
					input.pos++;
				}
            case ">":
                input.pos++;
                label = null;
				var quote = [];
				var h; //= parseHorizontal("@", true);
			    do {
					h = parseHorizontal("@");
                    quote.push(h);
				} while (peek(-1)!="@");
				if (quote.length == 0)
                    throw mkErr('Could not find quote');
				var quotetext = switch quote.length {
				case 1: quote[0];
				case _: mkExpr(HList(quote), quote[0].pos);
				}
                trace('quote is $quotetext \n ');
                var  author= [];
				var h = parseHorizontal(null, true);
				while (h != null) {
					author.push(h);
					h = parseHorizontal(null);
				}
				if (author.length == 0)
                    throw mkErr('Could not find author');
				var authortext = switch author.length {
				case 1: author[0];
				case _: mkExpr(HList(author), author[0].pos);
				}
				list.push(mkExpr(VQuote(quotetext, authortext, label), quotetext.pos));
			case _:
				label = null;
				var par = [];
				var h = parseHorizontal(null, true);
				while (h != null) {
					par.push(h);
					h = parseHorizontal(null);
				}
				if (par.length == 0)
					continue;
				var text = switch par.length {
				case 1: par[0];
				case _: mkExpr(HList(par), par[0].pos);
				}
				list.push(mkExpr(VPar(text, label), text.pos));
			}
		}
		return switch list.length {
		case 0: null;
		case 1: list[0];
		case _: mkExpr(VList(list), list[0].pos);
		}
	}

    function getVBlock() {
        var emptyLineRegex = "\\n( |\\t|\\r)+?\\n"
        var interest =  ["//","/\\*","\\\\pipe-in{", "\\\\start-ignore{", "`",  "```","\\n( |\\t|\\r)+?\\n"];
 // var interest =  ["//","\\\\pipe-in{(.*?)}", "\\\\start-ignore{(.*?)}", "`",  "```","\\n( |\\t|\\r)+?\\n"];
        var endinterest = "/n", "*/", "\n", "\\end-ignore{", "`", done, done, "```"];
        var block = new StringBuf() =  ""
        var find = readUntilPattern()
        block.add(find.left);
		switch find.found{
        case null:
            block.add(find.right);
        case "//":
            readUntil("\n");
            block.add(getVBlock())
        case "/*"
            readUntil("*/");
            // if (!firstthing && !lastthing && contain(\n \n)) warning("comment block not very visiblei");
            block.add(getVBlock())
        case "\\pipe-in{"
            //if (!startline) warning(should start line);
            pipeiIn (readUntil("}"));
            block.add(getVBlock())
        case "\\start-ignore":
            //if (!firstthing() and !lastthing) warning ("should be alone");
            readUntil("\\endignore{"+readUntil("}")+"}");
            //if (!firstthing and !lastthing) warning ("should be alone");
            block.add(getVBlock())
        case "`":
            block.add("`");
            block.add(readUntil("`",true);
            block.add(getVBlock())
        case "```" if (!find.left.trim=""):
            warning("code block (```) should start a vertical block");
            input.pos += find.pos.pos
        case "```"
            block.add("```");
            findend = readUntil('```',true);
            if (!ing) warning ("should be last thing");
        default:
        
        }
        return block.toString().trim
    }

        function readUntil(end) {
			var i = input.buf.indexOf(end, input.pos);
			var ret = i > -1 ? input.buf.substring(input.pos, i + end.length) : input.buf.substring(input.pos);
			input.pos += ret.length;
			return ret;
		}
         

       	while (true) {
			switch peek() {
			case null:
				break;
			case "/" if (peek(1) == "/"):
				readUntil("\n");
			case "/" if (peek(1) == "*"):
				var p = mkPos();
				readUntil("*/");
				if (input.buf.substr(input.pos - 2, 2) != "*/")
					throw mkErr("Unclosed comment", p);
			case "\r":
				input.pos++;
			case " ", "\t":
				input.pos++;
				if (!ltrim && peek(0) != null && !peek(0).isSpace(0))
					buf.add(" ");
			case "\n":
				input.pos++;
				input.lino++;
				if (StringTools.trim(buf.toString()) == "")
					return null;
				if (peek(0) != null && !peek(0).isSpace(0))
					buf.add(" ");
				break;
    
    
    
    }

	function parseDocument():Document
    {
        var ast:Document;
        while input.length > 0 
            addVBlock(getVBlock(),ast);
		return ast;
    }

    function pipeIn(relativeFilePath) 
    {
        trace ('Pipeing: $relativeFilePath' + $mkPos() );
        addInputBuffer(relativeFilePath)
    }

	public function parseFile(path:String)
	{
        var filePathSplit = path.split("/");
        var fileName = filePathSplit.pop();
        var fileDir = filePathSplit.join("/");
        addInputBuffer(fileName, fileDir);
		trace('Parsing from file: $path');
		return parseDocument();
	}

    public function parseStream(stream:haxe.io.Input, ?basePath=".")
    {
        addInputBuffer("stdin",basePath,stream.readAll()toString);
        trace('Parsing from the standard input');
        return parseDocument();
    }

	public function new() {}
}

