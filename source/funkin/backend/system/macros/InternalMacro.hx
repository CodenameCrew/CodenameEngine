/**
 * Hey CodenameCrews, whenever cne internal haxelibs are used (openfl, lime)
 * Please Convert all of these macro codes to that source code!
 */

package funkin.backend.system.macros;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import haxe.macro.ExprTools;

class InternalMacro {
	public static function init() {
		final buildMacro = 'funkin.backend.system.macros.InternalMacro';
		Compiler.addMetadata('@:build($buildMacro.buildNativeHTTPRequest())', 'lime._internal.backend.native.NativeHTTPRequest');
		Compiler.addMetadata('@:build($buildMacro.buildCairoGraphics())', 'openfl.display._internal.CairoGraphics');
		Compiler.addMetadata('@:build($buildMacro.buildBitmapData())', 'openfl.display.BitmapData');
		Compiler.addMetadata('@:build($buildMacro.buildOpenGLRenderer())', 'openfl.display.OpenGLRenderer');
	}

	// fix maxThreads locked to 1
	public static macro function buildNativeHTTPRequest():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		for (f in fields) if (f.name == 'loadData') switch (f.kind) {
			case FFun(func): switch (func.expr.expr) {
				case EBlock(exprs):
					exprs.insert(0, macro if (localThreadPool != null) localThreadPool.maxThreads = 2);
				default:
			}
			default:
		}
		return fields;
	}

	// fix hardware cairo
	public static macro function buildCairoGraphics():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		for (f in fields) if (f.name == 'createImagePattern') switch (f.kind) {
			case FFun(func): switch (func.expr.expr) {
				case EBlock(exprs):
					exprs.insert(0, macro if (bitmapFill.__surface == null) return null);
				default:
			}
			default:
		}
		return fields;
	}

	// fix cairo surface
	public static macro function buildBitmapData():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		for (f in fields) if (f.name == 'getSurface') switch (f.kind) {
			case FFun(func): switch (func.expr.expr) {
				case EBlock(exprs):
					exprs.insert(0, macro if (__surface != null) return __surface);
				default:
			}
			default:
		}
		return fields;
	}

	// fix innacruate EPSILON on pixel snapping auto something idfk
	// might aswell just make it so it doesnt use Matrix _pool
	public static macro function buildOpenGLRenderer():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields();
		for (f in fields) if (f.name == '__getMatrix') switch (f.kind) {
			case FFun(func): func.expr = macro {
				__matrix[0] = transform.a * __worldTransform.a + transform.b * __worldTransform.c;
				__matrix[1] = transform.a * __worldTransform.b + transform.b * __worldTransform.d;
				__matrix[2] = 0;
				__matrix[3] = 0;
				__matrix[4] = transform.c * __worldTransform.a + transform.d * __worldTransform.c;
				__matrix[5] = transform.c * __worldTransform.b + transform.d * __worldTransform.d;
				__matrix[6] = 0;
				__matrix[7] = 0;
				__matrix[8] = 0;
				__matrix[9] = 0;
				__matrix[10] = 1;
				__matrix[11] = 0;
				__matrix[12] = transform.tx * __worldTransform.a + transform.ty * __worldTransform.c + __worldTransform.tx;
				__matrix[13] = transform.tx * __worldTransform.b + transform.ty * __worldTransform.d + __worldTransform.ty;
				__matrix[14] = 0;
				__matrix[15] = 1;

				if (pixelSnapping == openfl.display.PixelSnapping.ALWAYS ||
					(pixelSnapping == openfl.display.PixelSnapping.AUTO
						&& __matrix[1] == 0 && __matrix[4] == 0
						&& __matrix[0] < 1.0000001 && __matrix[0] > 0.9999999
					)	&& __matrix[5] < 1.0000001 && __matrix[5] > 0.9999999
				) {
					__matrix[12] = Math.round(__matrix[12]);
					__matrix[13] = Math.round(__matrix[13]);
				}

				__matrix.append(__flipped ? __projectionFlipped : __projection);

				for (i in 0...16) __values[i] = __matrix[i];
				return __values;
			}
			default:
		}
		return fields;
	}
}
#else
class InternalMacro {}
#end