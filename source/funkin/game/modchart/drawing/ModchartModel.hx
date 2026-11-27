package funkin.game.modchart.drawing;

import lime.utils.UInt16Array;
import lime.graphics.opengl.GL;
import foxlite.texture.FoxTexture;
import foxlite.mesh.buffer.FoxVertexBufferType;
import foxlite.mesh.buffer.FoxVertexBuffer;
import foxlite.mesh.buffer.FoxIndexBuffer;
import foxlite.renderer.FoxRenderer;
import foxlite.polyfill.TypedArray;
import foxlite.mesh.FoxMesh;
import foxlite.material.*;
import foxlite.FoxCamera;
import foxlite.FoxShader;
import foxlite.FoxModel;

import openfl.display.BitmapData;
import openfl.geom.Vector3D;
import flixel.math.FlxAngle;

@:structInit
private class ZAndIndex {
	public var z:Float;
	public var index:Int;

	public static function apply(from:Array<ZAndIndex>, to:Int, z:Float, idx:Int) {
		if (to >= from.length) {
			var newObj:ZAndIndex = {z: z, index: idx};
			from.push(newObj);
			return newObj;
		}
		var obj:ZAndIndex = from[to];
		obj.z = z;
		obj.index = idx;
		return obj;
	}
}

/*
TODO:
- Utilize `curField` to allow for StrumLine transformations and proxies
  - Begin using instance rendering
- Utilize `curShader` to allow for custom processing
*/
@:access(foxlite.FoxShader)
class ModchartModel extends FoxModel {
	static var vertices:Array<Vector3D> = [for (i in 0...4) new Vector3D()];
	static var indexArray:Array<Int> = [];

	var lastShader:FoxShader;
	var glowAttribIdx:Int = -1;
	var glowBuffer:FoxVertexBuffer;
	
	var modMesh:FoxMesh;

	var manager:ModchartManager;

	// ok let me explain this.
	// with depth buffers, even if a pixel is fully transparent, if not discarded, IT WILL STILL WRITE TO DEPTH.
	// this is REALLY BAD for transparent objects, hence we have to z-sort like all the other modchart backends before this.
	var zAndIndex:Array<ZAndIndex> = [];

	var finalVertices:Array<Float> = [];
	var finalUvs:Array<Float> = [];
	var finalNormals:Array<Float> = [];

	var finalColors:Array<Float> = [];
	var finalStealth:Array<Float> = [];

	public var curTex:BitmapData;
	// public var curShader:FoxShader;
	// public var curField:StrumLine;
	public var elemCount:Int = 0;
	public var basicMaterial:FoxMaterial;

	public function new(manager:ModchartManager) {
		super();
		this.manager = manager;
		name = "ModchartModel";

		modMesh = new FoxMesh();
		modMesh.calculateBounds([-1, -1, 0, 1, -1, 0, -1, 1, 0, 1, 1, 0]);
		addMesh(modMesh);
		glowBuffer = new FoxVertexBuffer(0, 4, true);

		basicMaterial = FoxMaterial.create(FoxShader.fromAsset("engine/modchart", ["VERTEX_COLORS"]));
		basicMaterial.depthFunc = FoxDepthCompareMode.LESS_EQUAL;
		basicMaterial.shadowCulling = FoxTriangleFace.NONE; // Render shadow for front and back faces
		basicMaterial.blendMode = FoxBlendMode.PREMULTIPLIED_ALPHA; // iffy flixel yes, but it doesnt fight with framebuffer alphas
		basicMaterial.alphaScissor = 0.05; // Cutout invisible pixels
		modMesh.material = basicMaterial;
	}

	public function buildFromQueue(queue:QueuedDraw) {
		if (elemCount == 0) {
			curTex = getTex(queue);
			if (modMesh.material.textures.exists("bitmap"))
				modMesh.material.textures.get("bitmap").take(curTex);
			else
				modMesh.material.textures.set("bitmap", FoxTexture.wrap(curTex));
		}

		final frame = queue.frame.frame;
		final wid = queue.frame.angle != 0 ? frame.height : frame.width;
		final hei = queue.frame.angle != 0 ? frame.width : frame.height;

		vertices[0].setTo(0, 0, 0);
		vertices[1].setTo(wid, 0, 0);
		vertices[2].setTo(0, hei, 0);
		vertices[3].setTo(wid, hei, 0);

		final offsetAng = queue.object.frameOffsetAngle == null ? 0.0 : queue.object.frameOffsetAngle - queue.rotation.z;
		var frameSin = 0.0, frameCos = 1.0;
		if (offsetAng != 0) {
			frameSin = Math.sin(offsetAng * FlxAngle.TO_RAD);
			frameCos = Math.cos(offsetAng * FlxAngle.TO_RAD);
		}

		final offset = queue.object.offset;
		final origin = queue.object.origin;
		final frameOffset = queue.object.frameOffset;
		var totalZ = 0.0;
		for (vert in vertices) {
			vert.x += queue.frame.offset.x - origin.x;
			vert.y += queue.frame.offset.y - origin.y;

			if (offsetAng != 0) {
				final rotX = (vert.x * frameCos - vert.y * frameSin) - frameOffset.x;
				final rotY = (vert.x * frameSin + vert.y * frameCos) - frameOffset.y;
				vert.x = rotX * frameCos + rotY * frameSin; // apply sin(-theta) => -sin(theta)
				vert.y = -(rotX * frameSin) + rotY * frameCos;
			} else {
				vert.x -= frameOffset.x;
				vert.y -= frameOffset.y;
			}

			vert.x *= queue.scale.x;
			vert.y *= queue.scale.y;
			vert.z *= queue.scale.z;

			ModchartManager.rotateVec(vert, queue.rotation.x, queue.rotation.y, queue.rotation.z);

			vert.addToOutput(queue.position, vert);
			vert.x += origin.x - offset.x - queue.object.width * 0.5;
			vert.y += origin.y - offset.y - queue.object.height * 0.5;

			manager.editVertex(vert, queue);

			finalVertices.push((vert.x - FlxG.width * 0.5) / FlxG.height);
			finalVertices.push(0.5 - vert.y / FlxG.height); // distribute division and negate
			finalVertices.push(vert.z / FlxG.width);

			finalColors.push(queue.color.redMultiplier);
			finalColors.push(queue.color.greenMultiplier);
			finalColors.push(queue.color.blueMultiplier);
			finalColors.push(queue.color.alphaMultiplier * CoolUtil.bound(2 - queue.stealth * 2, 0, 1));
			finalStealth.push(queue.stealthColor.x);
			finalStealth.push(queue.stealthColor.y);
			finalStealth.push(queue.stealthColor.z);
			finalStealth.push(CoolUtil.bound(queue.stealth * 2, 0, 1));

			totalZ += vert.z;
		}

		final widDiv = 1 / queue.frame.parent.width;
		final heiDiv = 1 / queue.frame.parent.height;
		finalUvs.push(frame.x * widDiv); // TL
		finalUvs.push(frame.y * heiDiv);
		finalUvs.push((frame.x + frame.width) * widDiv); // TR
		finalUvs.push(frame.y * heiDiv);
		finalUvs.push(frame.x * widDiv); // BL
		finalUvs.push((frame.y + frame.height) * heiDiv);
		finalUvs.push((frame.x + frame.width) * widDiv); // BR
		finalUvs.push((frame.y + frame.height) * heiDiv);

		for (i in 0...12)
			finalNormals.push(i % 3 == 2 ? 1 : 0);

		// divided by 4 => multiplied by 0.25. RECIPROCALS BAYBEEEEEEEEEEEEE
		ZAndIndex.apply(zAndIndex, elemCount, totalZ * 0.25, elemCount);
		++elemCount;
	}

	override function renderMesh(mesh:FoxMesh, shader:FoxShader) {
		if (elemCount <= 0 || !modMesh.material.textures.exists("bitmap"))
			return;

		if (lastShader == null || shader != lastShader) {
			lastShader = shader;
			glowAttribIdx = shader.gl.getAttribLocation(shader.getGLProgram(), "glow");
		}
		shader.gl.useProgram(shader.getGLProgram());
		if (glowAttribIdx >= 0) {
			var packed = TypedArray.Float32Array(cast finalStealth);
			glowBuffer.count = elemCount;
			glowBuffer.uploadFromTypedArray(packed);
			FoxRenderer.setAttributePointerAt(glowAttribIdx, glowBuffer);
		}

		setMeshArrays();
		FoxRenderer.drawMesh(context, mesh, shader);

		var arrays:Array<Array<Any>> = [finalVertices, finalUvs, finalNormals, finalColors, finalStealth];
		for (arr in arrays)
			arr.resize(0);
		elemCount = 0;
	}
	override function draw(cam:FoxCamera) {
		if (elemCount <= 0)
			return;

		modMesh.calculateBounds(finalVertices);
		cacheBounds.copyFrom(modMesh.bounds);
		super.draw(cam);
	}


	// similar to FoxFlxSprite.getSpriteTexture()
	public static inline function getTex(queue:QueuedDraw) {
		return queue.frame.parent?.bitmap ?? queue.object.pixels;
	}

	// FoxMesh.setArrays but an attempt to reduce allocations, not well tested currently.
	function setMeshArrays() {
		if (indexArray.length != elemCount * 6)
			indexArray.resize(elemCount * 6);

		// this will need more testing since this may cause INCREASED allocation and deallocation
		// but i need sorting and i dont want to be constantly constructing, so hopefully there is reduced allocation
		zAndIndex.resize(elemCount);
		zAndIndex.sort(sortZ);
		for (i in 0...zAndIndex.length) {
			var idx = zAndIndex[i].index * 4; // get the * out of the way
			indexArray[i * 6] = idx;
			indexArray[i * 6 + 1] = idx + 1;
			indexArray[i * 6 + 2] = idx + 2;
			indexArray[i * 6 + 3] = idx + 1;
			indexArray[i * 6 + 4] = idx + 2;
			indexArray[i * 6 + 5] = idx + 3;
		}
		
		var idxBuffer:FoxVertexBuffer = modMesh.buffers[FoxVertexBufferType.INDICES];
		if (idxBuffer == null)
			modMesh.buffers[FoxVertexBufferType.INDICES] = idxBuffer = new FoxIndexBuffer(indexArray.length, 1);
		idxBuffer.usage = modMesh.bufferUsage;
		idxBuffer.count = indexArray.length;
		modMesh.setIndexBuffer(indexArray);

		checkBufferArr(FoxVertexBufferType.VERTICES, 3, finalVertices);
		checkBufferArr(FoxVertexBufferType.UVS, 2, finalUvs);
		checkBufferArr(FoxVertexBufferType.NORMALS, 3, finalNormals);
		checkBufferArr(FoxVertexBufferType.TANGENTS, 4, FoxMesh.computeTangents(finalVertices, finalUvs, finalNormals, indexArray));
		checkBufferArr(FoxVertexBufferType.COLORS, 4, finalColors);
	}
	function checkBufferArr(idx:Int, count:Int, array:Array<Float>) {
		var buffer = modMesh.buffers[idx];
		if (buffer == null)
			modMesh.buffers[idx] = buffer = new FoxVertexBuffer(elemCount, count);
		buffer.usage = modMesh.bufferUsage;
		buffer.count = elemCount;

		modMesh.setBuffer(idx, array);
	}

	override function destroy() {
		super.destroy();
		glowBuffer.dispose();
	}

	static function sortZ(a:ZAndIndex, b:ZAndIndex) {
		return Std.int(a.z - b.z);
	}
}