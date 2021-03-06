package format;

import StringTools.htmlEscape;
import StringTools.urlEncode;
import format.Document;

typedef OutputApi = {
	function saveContent(path:String, content:String):Void;
}

class HtmlGenerator implements Generator {
	var api:OutputApi;

	function posAttrs(pos:Pos)
		return 'x-src-file="${htmlEscape(pos.fileName)}" x-src-line=${pos.lineNumber}';

	function generateHorizontal(expr:Expr<HDef>)
	{
		if (expr == null)
			return "";
		return switch expr.expr {
		case HText(text):
			'<span ${posAttrs(expr.pos)}>${htmlEscape(text)}</span>';
		case HEmph(expr):
			'<em ${posAttrs(expr.pos)}>${generateHorizontal(expr)}</em>';
		case HHighlight(expr):
			'<strong ${posAttrs(expr.pos)}>${generateHorizontal(expr)}</strong>';
		case HList(list):
			[ for (h in list) generateHorizontal(h) ].join("");
		}
	}

	function indent(depth:Int)
		return depth > 0 ? StringTools.rpad("", "\t", depth) : "";

	function generateVertical(expr:Expr<VDef>, ?curDepth=0, ?curLabel="")
	{
		if (expr == null)
			return "";
		return switch expr.expr {
		case VPar(par):
			indent(curDepth) + '<p ${posAttrs(expr.pos)}>${generateHorizontal(par)}</p>';
		case VSection(label, name, contents):
			var dep = curDepth + 1;
			var lab = curLabel != "" ? '$curLabel.$label' : label;
			var cl = dep == 1 ? "chapter" : "section";
			indent(curDepth) + '<article class="$cl" id="${urlEncode(lab)}" ${posAttrs(expr.pos)}>\n' +
			indent(dep) + '<h$dep ${posAttrs(expr.pos)}>${generateHorizontal(name)}</h$dep>\n' +
			generateVertical(contents, dep, lab) + "\n" +
			indent(curDepth) + "</article>";
		case VList(list):
			[ for (v in list) generateVertical(v, curDepth, curLabel) ].join("\n");
		}
	}

	public function generateDocument(doc:Document)
		api.saveContent("index.html", generateVertical(doc));

	public function new(?api:OutputApi) {
		if (api == null)
			api = sys.io.File;
		this.api = api;
	}
}

