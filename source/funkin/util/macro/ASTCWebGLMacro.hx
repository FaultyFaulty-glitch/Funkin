package funkin.util.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;

/**
 * Patches OpenFL's ASTC extension-name lookups for HTML5 builds.
 *
 * OpenFL uses the native KHR extension name. WebGL exposes the ASTC formats
 * through WEBGL_compressed_texture_astc, while retaining the KHR format constants.
 * The ASTC texture constructor is also instrumented so the browser console can
 * confirm that compressed GPU textures were actually created.
 */
class ASTCWebGLMacro
{
  public static macro function patch():Array<haxe.macro.Expr.Field>
  {
    final fields:Array<haxe.macro.Expr.Field> = Context.getBuildFields();

    if (Context.defined("js") && Context.defined("html5"))
    {
      final localClass = Context.getLocalClass();
      final className:String = localClass == null ? "" : localClass.get().pack.concat([localClass.get().name]).join(".");
      final instrumentASTCTexture:Bool = className == "openfl.display3D.textures.ASTCTexture";
      final patchAssetLibrary:Bool = className == "lime.utils.AssetLibrary";

      for (field in fields)
      {
        switch (field.kind)
        {
          case FFun(method) if (method.expr != null):
            var patchedExpr:Expr = ExprTools.map(method.expr, function(expression:Expr):Expr
            {
              return switch (expression.expr)
              {
                case EConst(CString(value, _)) if (value == "KHR_texture_compression_astc_ldr"):
                  macro "WEBGL_compressed_texture_astc";
                default:
                  expression;
              };
            });

            if (patchAssetLibrary && field.name == "load")
            {
              // The default Lime asset-library loader eagerly decodes every preloaded
              // PNG, even when an ASTC companion is available. Skip only those PNGs
              // when this browser's actual rendering context supports ASTC.
              patchedExpr = ExprTools.map(patchedExpr, function(expression:Expr):Expr
              {
                return switch (expression.expr)
                {
                  case EFor(iterator, body):
                    final isAssetIdLoop:Bool = switch (iterator.expr)
                    {
                      case EBinop(OpIn, {expr: EConst(CIdent("id"))}, _): true;
                      default: false;
                    };

                    if (!isAssetIdLoop)
                    {
                      expression;
                    }
                    else
                    {
                      final skipPngPreload:Expr = macro
                      {
                        if (funkin.util.ASTCRuntime.shouldSkipPngPreload(id, this))
                        {
                          continue;
                        }
                      };

                      final patchedBody:Expr = switch (body.expr)
                      {
                        case EBlock(expressions):
                          expressions.unshift(skipPngPreload);
                          body;
                        default:
                          {expr: EBlock([skipPngPreload, body]), pos: body.pos};
                      };

                      {expr: EFor(iterator, patchedBody), pos: expression.pos};
                    }

                  default:
                    expression;
                };
              });
            }

            if (instrumentASTCTexture && field.name == "new")
            {
              // Append after the constructor's existing statements so super(context)
              // remains the first constructor operation.
              switch (patchedExpr.expr)
              {
                case EBlock(expressions):
                  expressions.push(macro funkin.util.ASTCRuntime.recordUpload());
                  method.expr = {expr: EBlock(expressions), pos: patchedExpr.pos};
                default:
                  method.expr = patchedExpr;
              }
            }
            else
            {
              method.expr = patchedExpr;
            }

          default:
        }
      }
    }

    return fields;
  }
}
#end
