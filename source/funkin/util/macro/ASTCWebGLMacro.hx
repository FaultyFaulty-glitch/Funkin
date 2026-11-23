package funkin.util.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;

/**
 * Patches OpenFL's ASTC extension-name lookups for HTML5 builds.
 *
 * OpenFL uses the native GL_KHR_texture_compression_astc_ldr name.
 * WebGL exposes the same ASTC formats through WEBGL_compressed_texture_astc.
 * The extension's format constants retain their KHR names, so only the
 * extension string itself needs to change.
 */
class ASTCWebGLMacro
{
  public static macro function patch():Array<haxe.macro.Expr.Field>
  {
    final fields:Array<haxe.macro.Expr.Field> = Context.getBuildFields();

    if (Context.defined("js") && Context.defined("html5"))
    {
      for (field in fields)
      {
        switch (field.kind)
        {
          case FFun(method) if (method.expr != null):
            method.expr = ExprTools.map(method.expr, function(expression:Expr):Expr
            {
              return switch (expression.expr)
              {
                case EConst(CString(value, _)) if (value == "KHR_texture_compression_astc_ldr"):
                  macro "WEBGL_compressed_texture_astc";
                default:
                  expression;
              };
            });
          default:
        }
      }
    }

    return fields;
  }
}
#end
