package format;

class HtmlGeneration {
	public static function main()
	{
		trace("TODO something");
		Sys.exit(1);
	}
}

class Main {
	static function main()
	{
		var err = Sys.stderr();
		haxe.Log.trace = function (msg:Dynamic, ?pos:haxe.PosInfos) {
			var msg = StringTools.replace(Std.string(msg), "\n", "\n... ");
			if (pos.customParams != null)
				msg += StringTools.replace(pos.customParams.join("\n"), "\n", "\n... ");
			err.writeString('${pos.className.split(".").pop().toUpperCase()}  $msg  @${pos.fileName}:${pos.lineNumber}\n');
		}

#if (cli == "generate-html")
		HtmlGeneration.main();
#elseif (cli == "generate-tex")
		throw("Not implemented here");
#elseif (cli == "generate-parser")
		throw("Not implemented here");
#else
	
        if (Sys.args().length==0) {trace('argument required'); Sys.exit(1);}
        if (!sys.FileSystem.exists(Sys.args()[0])) {trace('file not found:' + Sys.args()[0]); Sys.exit(1);}
        var p = new format.Parser();
		var doc = p.parseFile(Sys.args()[0]);
		// trace(doc);

		var buf = new StringBuf();
		var api = {
			saveContent : function (path, content) {
                buf.add('<!DOCTYPE html>\n');
                buf.add('\n');
                buf.add('<html>\n');
                buf.add('<head>\n');
                buf.add('    <title>Basic concepts</title>\n');
                buf.add('    <link rel="stylesheet" href="brtpg.css">\n');
                buf.add('    <script type="text/javascript" src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML"></script>\n');
                buf.add('</head>\n');
                buf.add('<body>\n');
				buf.add('<!-- file $path -->\n');
				buf.add(content);
				buf.add("\n\n");
                buf.add('</body>\n');
                buf.add('</html>\n');
			}
		}
		var hgen = new format.HtmlGenerator(api);
		hgen.generateDocument(doc);
		Sys.println(buf.toString());
#end
	}
}

