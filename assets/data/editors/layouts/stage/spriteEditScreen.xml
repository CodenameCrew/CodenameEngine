<window width="1056" height="520" title="${translate('win-sprite-title', [button.getName()])}">
	<set name="MARGIN" value="20" />
	<set name="XOFFSET" value="50" />
	<set name="YOFFSET" value="40" />
	<set name="TO" value="64" />

	<exec>
		function col(c:Int) {
			return 20 + (200 + XOFFSET) * c;
		}

		if(sprite.animateAtlas == null) {
			previewSprite =  new FunkinSprite(50, self.winHeight - 100);
			previewSprite.frame = sprite.frame;

			self.add(previewSprite);
		}
	</exec>

	<title name="title" x="20" y="30 + 16" text="${translate('sprite-title')}" />

	<section> <!-- ROW 1 -->
		<set name="curY" value="title.y + TO" />

		<textbox name="nameTextBox" label="${translate('nameID')}" value="button.getName()"   x="col(0)" y="curY" width="200" height="32" />
		<textbox name="spriteTextBox" value="getEx('imageFile')" x="last.x + last.bWidth + XOFFSET" y="curY" width="200" height="32" />
		<stepper name="alphaStepper" label="Alpha" value="sprite.alpha" x="spriteTextBox.x + spriteTextBox.bWidth + XOFFSET" y="curY" precision="2" step="0.01" width="100" />
		<label name="imageFile" text="${translate('imageFile')}" x="spriteTextBox.x" y="spriteTextBox.y - 14" size="15" />
	</section>

	<section> <!-- ROW 2 -->
		<set name="curY" value="nameTextBox.y + nameTextBox.bHeight + YOFFSET" />

		<stepper name="xStepper" label="X" value="sprite.x" x="col(0)" y="curY" step="1" width="100" />
		<stepper name="yStepper" label="Y" value="sprite.y" x="last.x + last.bWidth + XOFFSET - 20" y="curY" step="1" width="100" />

		<stepper name="scrollXStepper" label="${translate('scroll', ['X'])}" value="sprite.scrollFactor.x" x="spriteTextBox.x" y="curY" precision="2" step="0.01" width="100" />
		<stepper name="scrollYStepper" label="${translate('scroll', ['Y'])}" value="sprite.scrollFactor.y" x="last.x + last.bWidth + XOFFSET - 20" y="curY" precision="2" step="0.01" width="100" />

		<stepper name="scaleXStepper" label="${translate('scale', ['X'])}" value="sprite.scale.x" x="col(2)" y="curY" precision="2" step="0.01" width="100" />
		<stepper name="scaleYStepper" label="${translate('scale', ['Y'])}" value="sprite.scale.y" x="last.x + last.bWidth + XOFFSET - 20" y="curY" precision="2" step="0.01" width="100" />
	</section>

	<section> <!-- ROW 3 -->
		<set name="curY" value="xStepper.y + xStepper.bHeight + YOFFSET" />

		<stepper name="angleStepper" label="${translate('angle')}" value="sprite.angle" x="col(0)" y="curY" precision="2" step="0.01" width="100" />
		<stepper name="zoomFactorStepper" label="${translate('zoomFactor')}" value="sprite.zoomFactor" x="last.x + last.bWidth + XOFFSET - 20" y="curY" precision="2" step="0.01" width="100" />

		<!-- TODO: Simplify this -->
		<dropdown name="animType" label="${translate('animType')}" value="sprite.spriteAnimType" x="col(1)" y="curY" width="150" height="32">
			<item label="${translate('animType.none')}" value="0" />
			<item label="${translate('animType.beat')}" value="1" />
			<item label="${translate('animType.loop')}" value="2" />
		</dropdown>

		<stepper name="skewXStepper" label="${translate('skew', ['X'])}" value="sprite.skew.x" x="col(2)" y="curY" precision="2" step="0.01" width="100" />
		<stepper name="skewYStepper" label="${translate('skew', ['Y'])}" value="sprite.skew.y" x="last.x + last.bWidth + XOFFSET - 20" y="curY" precision="2" step="0.01" width="100" />
	</section>

	<section> <!-- ROW 4 -->
		<set name="curY" value="angleStepper.y + angleStepper.bHeight + YOFFSET" />

		<checkbox name="antialiasingCheckbox" text="${translate('antialiasing')}" value="sprite.antialiasing" x="col(0)" y="curY" />
		<radio for="memoryCheck" name="highMemoryRadio" text="${translate('highMemory')}" value="getEx('highMemory')" x="col(1)" y="curY" />
		<radio for="memoryCheck" name="lowMemoryRadio" text="${translate('lowMemory')}" value="getEx('lowMemory')" x="col(2)" y="curY" />

		<!-- TODO: Animation list -->
	</section>

	<section> <!-- RIGHT SIDE -->
		<set name="curY" value="title.y + TO" />
		<set name="listWidth" value="250" />

		<buttonlist name="animations" label="${translate('animations')}" x="col(3)" y="curY" width="listWidth" height="330" buttonSizeX="listWidth-10" buttonSizeY="35" buttonSpacing="5">
			<texture path="editors/ui/inputbox" />
			<camSpacing value="0" />

			<code>
				buttonlist.addButton.exists = false;
			</code>

			<!-- <code>
				import funkin.editors.extra.PropertyButton;

				var buttonList = buttonlist; // important for now, since it gets reset after the code is run

				var width = buttonList.buttonSize.x;
				var height = buttonList.buttonSize.y;

				buttonList.addButton.callback = function() {
					buttonList.add(new PropertyButton("newProperty", "valueHere", buttonList, width, height, 150, 220, 25));
				}

				//var defaultAttribs = Stage.DEFAULT_ATTRIBUTES;
				//for (i in stage.stageXML.attributes()) {
				//	trace(i, defaultAttribs);
				//	if (!defaultAttribs.contains(i))
				//		buttonList.add(new PropertyButton(i, stage.stageXML.get(i), buttonList, width, height, 150, 220, 25));
				//}
				for(key =&gt; val in stage.extra)
					buttonList.add(new PropertyButton(key, val, buttonList, width, height, 150, 220, 25));
			</code> -->
		</buttonlist>

		<text text="${translate('tipCustomProperties')}" x="col(2) - 60" y="self.winHeight - 50" size="15" />
	</section>


	<!-- Preview Transform -->

	<section if="previewSprite != null">
		<title name="previewTitle" x="20" y="self.winHeight - 150" text="${translate('transformPreview')}" size="15" />
    </section>

	<exec>
		function onUpdate() {
			if(previewSprite == null) return;
			previewSprite.color = 0xFFFFFFFF; // TODO: Color Wheel
			previewSprite.skew.x = skewXStepper.value;
			previewSprite.skew.y = skewYStepper.value;
			previewSprite.angle = angleStepper.value;
			previewSprite.alpha = alphaStepper.value;
			previewSprite.antialiasing = antialiasingCheckbox.checked;
			var ratio = sprite.width / sprite.height;
			previewSprite.setGraphicSize(50 * scaleXStepper.value * ratio, 50 * scaleYStepper.value);
			previewSprite.updateHitbox();
		}

		function onSave() {
			sprite.name = nameTextBox.label.text;
			setEx("imageFile", spriteTextBox.label.text);

			setEx("highMemory", highMemoryRadio.checked);
			setEx("lowMemory", lowMemoryRadio.checked);

			//sprite.x = xStepper.value;
			//sprite.y = yStepper.value;
			//sprite.zoomFactor = zoomFactorStepper.value;
			//sprite.antialiasing = antialiasingCheckbox.checked;
			//sprite.color = colorWheel.color;
			//sprite.spriteAnimType = animType.value;
			sprite.angle = angleStepper.value;
			sprite.alpha = alphaStepper.value;

			function saveXY(obj:Dynamic, name:String, x:UINumericStepper, y:UINumericStepper) {
				button.xml.remove(name + "");
				button.xml.remove(name + "x");
				button.xml.remove(name + "y");

				obj.x = x.value;
				obj.y = y.value;

				if(x.value == y.value)
					button.xml.set(name, x.value);
				else {
					button.xml.set(name + "x", x.value);
					button.xml.set(name + "y", y.value);
				}
			}
			function save(name:String, value:Dynamic) {
				button.xml.remove(name);
				button.xml.set(name, value);
			}

			// TODO: remove old attributes to prevent possible errors
			// button.xml.remove();

			button.xml.set("name", nameTextBox.label.text);
			button.xml.set("sprite", spriteTextBox.label.text);
			button.xml.set("x", xStepper.value);
			button.xml.set("y", yStepper.value);
			button.xml.set("zoom", zoomFactorStepper.value);
			button.xml.set("type", animType.key);
			button.xml.set("antialiasing", antialiasingCheckbox.checked);
			button.xml.set("angle", angleStepper.value);
			button.xml.set("alpha", alphaStepper.value);

			saveXY(sprite.scrollFactor, "scroll", scrollXStepper, scrollYStepper);
			saveXY(sprite.scale, "scale", scaleXStepper, scaleYStepper);
			saveXY(sprite.skew, "skew", skewXStepper, skewYStepper);
			XMLUtil.loadSpriteFromXML(sprite, button.xml, stage.spritesParentFolder);
		}
	</exec>
</window>