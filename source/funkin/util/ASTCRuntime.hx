package funkin.util;

/**
 * Runtime diagnostics for the HTML5 ASTC texture path.
 */
class ASTCRuntime
{
  static var uploadedTextureCount:Int = 0;

  /**
   * Called after OpenFL successfully constructs and uploads an ASTC texture.
   */
  public static function recordUpload():Void
  {
    uploadedTextureCount++;

    if (uploadedTextureCount == 1)
    {
      trace('[ASTC] First compressed GPU texture uploaded successfully.');
    }
  }

  /**
   * Returns the number of ASTC textures created during this session.
   */
  public static function getUploadedTextureCount():Int
  {
    return uploadedTextureCount;
  }

  static var skippedPngPreloadCount:Int = 0;
  static var loggedPreloadSkip:Bool = false;

  /**
   * Determines whether Lime should skip eagerly loading a PNG whose ASTC
   * companion can be used by the current HTML5 rendering context.
   */
  public static function shouldSkipPngPreload(assetId:String, library:lime.utils.AssetLibrary):Bool
  {
    #if (js && html5)
    if (assetId == null || !StringTools.endsWith(assetId, ".png")) return false;

    try
    {
      final context = openfl.Lib.current.stage.context3D;
      if (context == null || !context.isASTCSupported()) return false;

      final astcPath:String = haxe.io.Path.withExtension(assetId, "astc");
      if (!library.exists(astcPath, "BINARY")) return false;

      skippedPngPreloadCount++;
      if (!loggedPreloadSkip)
      {
        loggedPreloadSkip = true;
        trace('[ASTC] Skipping eager PNG preloads; ASTC is supported by this rendering context.');
      }

      return true;
    }
    catch (error:Dynamic)
    {
      // If the rendering context is not ready yet, retain the PNG fallback.
      return false;
    }
    #else
    return false;
    #end
  }

  /**
   * Returns the number of PNG preloads skipped for ASTC-capable HTML5 browsers.
   */
  public static function getSkippedPngPreloadCount():Int
  {
    return skippedPngPreloadCount;
  }
}
}
