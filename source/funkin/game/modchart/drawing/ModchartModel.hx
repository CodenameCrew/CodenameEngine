package funkin.game.modchart.drawing;

import foxlite.texture.FoxTexture;
import foxlite.mesh.buffer.FoxVertexBufferType;
import foxlite.mesh.buffer.FoxVertexBuffer;
import foxlite.mesh.buffer.FoxIndexBuffer;
import foxlite.material.FoxTriangleFace;
import foxlite.material.FoxBlendMode;
import foxlite.material.FoxMaterial;
import foxlite.renderer.FoxRenderer;
import foxlite.polyfill.TypedArray;
import foxlite.mesh.FoxMesh;
import foxlite.FoxCamera;
import foxlite.FoxShader;
import foxlite.FoxModel;

import openfl.display.BitmapData;
import openfl.geom.Vector3D;
import flixel.math.FlxAngle;

/*
TODO:
- Utilize `curField` to allow for StrumLine transformations and proxies
  - Begin using instance rendering
- Utilize `curShader` to allow for custom processing
*/
@:access(foxlite.FoxShader)
class ModchartModel extends FoxModel {
	static var vertices:Array<Vector3D> = [for (i in 0...4) new Vector3D()];

	var lastShader:FoxShader;
	var glowAttribIdx:Int = -1;
	var glowBuffer:FoxVertexBuffer;
	
	var modMesh:FoxMesh;

	var manager:ModchartManager;

	var finalVertices:Array<Float> = [];
	var finalUvs:Array<Float> = [];
	var finalNormals:Array<Float> = [];
	var finalIndices:Array<Int> = [];

	var finalColors:Array<Float> = [];
	var finalStealth:Array<Float> = [];

	public var curTex:BitmapData;
	// public var curShader:FoxShader;
	// public var curField:StrumLine;
	public var elemCount:Int = 0;

	public function new(manager:ModchartManager) {
		super();
		this.manager = manager;
		name = "ModchartModel";

		modMesh = new FoxMesh();
		modMesh.calculateBounds([-1, -1, 0, 1, -1, 0, -1, 1, 0, 1, 1, 0]);
		addMesh(modMesh);
		glowBuffer = new FoxVertexBuffer(0, 4, true);

		var material = FoxMaterial.create(FoxShader.fromAsset(FoxShader.BASIC));
		material.shadowCulling = FoxTriangleFace.NONE; // Render shadow for front and back faces
		material.blendMode = FoxBlendMode.MIX; 
		material.alphaScissor = 0.05; // Cutout invisible pixels
		modMesh.material = material;
	}

	public function buildFromQueue(queue:QueuedDraw) {
		if (elemCount == 0) {
			curTex = getTex(queue);
			if (modMesh.material.textures.exists("bitmap"))
				modMesh.material.textures.get("bitmap").take(curTex);
			else
				modMesh.material.textures.set("bitmap", FoxTexture.wrap(curTex));
		}

		var frame = queue.frame.frame;
		var wid = queue.frame.angle != 0 ? frame.height : frame.width;
		var hei = queue.frame.angle != 0 ? frame.width : frame.height;

		vertices[0].setTo(0, 0, 0);
		vertices[1].setTo(wid, 0, 0);
		vertices[2].setTo(0, hei, 0);
		vertices[3].setTo(wid, hei, 0);

		var offsetAng = queue.object.frameOffsetAngle == null ? 0.0 : queue.object.frameOffsetAngle - queue.rotation.z;
		var frameSin = 0.0, frameCos = 1.0;
		if (offsetAng != 0) {
			frameSin = Math.sin(offsetAng * FlxAngle.TO_RAD);
			frameCos = Math.cos(offsetAng * FlxAngle.TO_RAD);
		}

		var offset = queue.object.offset;
		var origin = queue.object.origin;
		var frameOffset = queue.object.frameOffset;
		for (vert in vertices) {
			vert.x += queue.frame.offset.x - origin.x;
			vert.y += queue.frame.offset.y - origin.y;

			if (offsetAng != 0) {
				var rotX = (vert.x * frameCos - vert.y * frameSin) - frameOffset.x;
				var rotY = (vert.x * frameSin + vert.y * frameCos) - frameOffset.y;
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
			finalColors.push(queue.color.alphaMultiplier);
			finalStealth.push(queue.stealthColor.x);
			finalStealth.push(queue.stealthColor.y);
			finalStealth.push(queue.stealthColor.z);
			finalStealth.push(queue.stealth);
		}

		var widDiv = 1 / queue.frame.parent.width;
		var heiDiv = 1 / queue.frame.parent.height;
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

		finalIndices.push(elemCount * 4);
		finalIndices.push(elemCount * 4 + 1);
		finalIndices.push(elemCount * 4 + 2);
		finalIndices.push(elemCount * 4 + 1);
		finalIndices.push(elemCount * 4 + 2);
		finalIndices.push(elemCount * 4 + 3);
		++elemCount;
	}

	override function renderMesh(mesh:FoxMesh, shader:FoxShader) {
		if (elemCount <= 0 || !modMesh.material.textures.exists("bitmap"))
			return;

		if (lastShader == null || shader != lastShader) {
			lastShader = shader;
			shader.gl.useProgram(shader.getGLProgram());
			glowAttribIdx = shader.gl.getAttribLocation(shader.getGLProgram(), "glow");
		}
		if (glowAttribIdx >= 0) {
			var packed = TypedArray.Float32Array(cast finalStealth);
			glowBuffer.uploadFromTypedArray(packed);
			FoxRenderer.setAttributePointerAt(glowAttribIdx, glowBuffer);
		}

		setMeshArrays();
		FoxRenderer.drawMesh(context, mesh, shader);

		var arrays:Array<Array<Any>> = [finalVertices, finalUvs, finalNormals, finalIndices, finalColors];
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
		var idxBuffer:FoxVertexBuffer = modMesh.buffers[FoxVertexBufferType.INDICES];
		if (idxBuffer == null)
			modMesh.buffers[FoxVertexBufferType.INDICES] = idxBuffer = new FoxIndexBuffer(finalIndices.length, 1);
		idxBuffer.usage = modMesh.bufferUsage;
		idxBuffer.count = finalIndices.length;
		modMesh.setIndexBuffer(finalIndices);

		checkBufferArr(FoxVertexBufferType.VERTICES, 3, finalVertices);
		checkBufferArr(FoxVertexBufferType.UVS, 2, finalUvs);
		checkBufferArr(FoxVertexBufferType.NORMALS, 3, finalNormals);
		checkBufferArr(FoxVertexBufferType.TANGENTS, 4, FoxMesh.computeTangents(finalVertices, finalUvs, finalNormals, finalIndices));
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
}