package funkin.backend.system.macros;

#if macro
import sys.io.File;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Printer;
import haxe.macro.Expr.Position;
import haxe.macro.Context;
import haxe.macro.Expr.Field;
import haxe.macro.Expr;

class AliasMacro {
    public static var aliasMetadata:Metadata = [{
        name: ":keep",
        pos: Context.currentPos()
    },{
        name: ":dox",
        pos: Context.currentPos(),
        params: [
            {
                expr: EConst(CIdent("hide")),
                pos: Context.currentPos()
            }
        ]
    }];

    public static function build():Array<Field> {
        #if display
        return Context.getBuildFields();
        #end
        
        var fields = Context.getBuildFields();
        var ogFieldCount = fields.length;

        for(i in 0...ogFieldCount) {
            var field = fields[i];
            if (field.meta == null) continue;

            var previousAliases:Array<{name:String, pos:Position}> = [];
            for(meta in field.meta) {
                if (meta.name == ":alias" && meta.params != null) {
                    for(p in meta.params) {
                        switch(p.expr) {
                            case EConst(CString(s, kind)):
                                previousAliases.push({
                                    name: s,
                                    pos: p.pos
                                });
                            default:
                        }
                    }
                }
            }

            if (previousAliases.length == 0) continue;

            var ghostAccess = field.access.copy();
            ghostAccess.remove(AOverride);
            ghostAccess.remove(APublic);

            for(alias in previousAliases) {
                var ghostField:Field = {
                    name: alias.name,
                    pos: alias.pos,
                    kind: null,
                    access: ghostAccess,
                    meta: aliasMetadata
                };

                switch(field.kind) {
                    case FFun(f):
                        var args:Array<Expr> = [for(a in f.args) {
                            expr: EConst(CIdent(a.name)),
                            pos: Context.currentPos()
                        }];

                        ghostField.kind = FFun({
                            args: f.args,
                            params: f.params,
                            ret: f.ret,
                            expr: macro return $i{field.name}($a{args})
                        });

                    default:
                        var type = null;
                        switch(field.kind) {
                            case FVar(t, e):
                                type = t;
                            case FProp(get, set, t, e):
                                type = t;
                            default:
                        }
                        ghostField.kind = FProp("get", "set", type, null);

                        fields.push({
                            name: 'get_${alias.name}',
                            kind: FFun({
                                args: [],
                                expr: macro return $i{field.name},
                                ret: type
                            }),
                            pos: alias.pos,
                            meta: aliasMetadata
                        });
                        fields.push({
                            name: 'set_${alias.name}',
                            kind: FFun({
                                args: [{
                                    name: '_${field.name}',
                                    type: type
                                }],
                                expr: macro return ($i{field.name} = $i{'_${field.name}'}),
                                ret: type
                            }),
                            pos: alias.pos,
                            meta: aliasMetadata
                        });
                }

                fields.push(ghostField);
            }

            var docFooter = '_Aliases: ${[for(alias in previousAliases) '`${alias.name}`'].join(", ")}_';
            if (field.doc != null)
                field.doc += '\n\n$docFooter'; 
            else
                field.doc = docFooter;
        }
		trace(fields);

        return fields;
    }
}
#end