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
}
