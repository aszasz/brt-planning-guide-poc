package format;

enum ArgType {
    ATLabel;
    ATPath;
    ATInteger;
    ATFloat;
}

typedef ArgDef ={
    optional: Bool,
    type:ArgType
}

typedef SlashCommandDef = {
    name: String
    arglist: Null<Array<ArgDef>>
}

enum SlashCommands {
    Fignum (label

}
