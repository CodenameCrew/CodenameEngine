<window width="550" height="570" title="${translate('win-character-title', [button.getName()])}">
	<set name="XOFFSET" value="30" />
	<set name="YOFFSET" value="40" />
	<set name="TO" value="64" />

	<exec>
		function col(c:Int) {
			return 20 + (150 + XOFFSET) * c;
		}
		previewSprite = null;
		if(char.animateAtlas == null) {
			previewSprite = new FunkinSprite(0, 0);
			previewSprite.frame = char.frame;

			self.add(previewSprite);
		}
	</exec>

	<title name="title" x="20" y="30 + 16" text="${translate('character-title')}" />

	<section>
		<set name="curY" value="title.y + TO" />

		<stepper name="xStepper" label="X" value="char.x" x="col(0)" y="curY" step="1" width="100" />
		<stepper name="yStepper" label="Y" value="char.y" x="last.x + last.bWidth + XOFFSET - 20" y="curY" step="1" width="100" />

		<stepper name="scrollXStepper" label="${translate('scroll', ['X'])}" value="char.scrollFactor.x" x="col(1)" y="curY" precision="2" step="0.01" width="100" />
		<stepper name="scrollYStepper" label="${translate('scroll', ['Y'])}" value="char.scrollFactor.y" x="last.x + last.bWidth + XOFFSET - 20" y="curY" precision="2" step="0.01" width="100" />

		<stepper name="scaleXStepper" label="${translate('scale', ['X'])}" value="char.scale.x / charScale" x="col(2)" y="curY" precision="2" step="0.01" width="100" />
		<stepper name="scaleYStepper" label="${translate('scale', ['Y'])}" value="char.scale.y / charScale" x="last.x + last.bWidth + XOFFSET - 20" y="curY" precision="2" step="0.01" width="100" />
	</section>

	<section>
		<set name="curY" value="xStepper.y + xStepper.bHeight + YOFFSET" />

		<stepper name="camxStepper" label="${translate('camera', ['X'])}" value="getEx('camX')" x="col(0)" y="curY" step="1" width="100" />
		<stepper name="camyStepper" label="${translate('camera', ['Y'])}" value="getEx('camY')" x="last.x + last.bWidth + XOFFSET - 20" y="curY" step="1" width="100" />

		<label name="spacingLabel" text="${translate('spacing')}" x="col(1)" y="curY" size="15" />
		<stepper name="spacingXStepper" value="getEx('spacingX')" x="col(1)" y="curY" precision="2" step="0.01" width="100" />
		<stepper name="spacingYStepper" value="getEx('spacingY')" x="last.x + last.bWidth + XOFFSET - 20" y="curY" precision="2" step="0.01" width="100" />

		<stepper name="skewXStepper" label="${translate('skew', ['X'])}" value="char.skew.x" x="col(2)" y="curY" precision="2" step="0.01" width="100" />
		<stepper name="skewYStepper" label="${translate('skew', ['Y'])}" value="char.skew.y" x="last.x + last.bWidth + XOFFSET - 20" y="curY" precision="2" step="0.01" width="100" />
	</section>

	<section>
		<set name="curY" value="camxStepper.y + camxStepper.bHeight + YOFFSET" />

		<stepper name="alphaStepper" label="${translate('alpha')}" value="char.alpha / 0.75" x="col(0)" y="curY" precision="2" step="0.01" width="100" />
		<stepper name="angleStepper" label="${translate('angle')}" value="char.angle" x="last.x + last.bWidth + XOFFSET - 20" y="curY" precision="2" step="0.01" width="100" />

		<stepper name="zoomFactorStepper" label="${translate('zoomFactor')}" value="char.zoomFactor" x="col(1)" y="curY" precision="2" step="0.01" width="100" />

		<section if="!StringTools.startsWith(char.name, 'NO_DELETE_')">
			<textbox name="charName" label="${translate('positionName')}" value="char.name" x="col(2)" y="curY" width="100"/>
		</section>
	</section>

	<section>
		<set name="curY" value="alphaStepper.y + alphaStepper.bHeight + YOFFSET - 20" />

		<checkbox name="flipXCheckbox" text="${translate('flipX')}" value="char.isPlayer" x="col(0)" y="curY" />

		<radio for="memoryCheck" name="highMemoryRadio" text="${translate('highMemory')}" value="getEx('highMemory')" x="last.field.x + last.field.width + XOFFSET * 2" y="curY" />
		<radio for="memoryCheck" name="lowMemoryRadio" text="${translate('lowMemory')}" value="getEx('lowMemory')" x="last.field.x + last.field.width + XOFFSET * 2" y="curY" />
	</section>

	<section if="previewSprite != null">
		<title name="previewTitle" x="20" y="self.winHeight - 220" text="${translate('transformPreview')}" size="15" />
	</section>
	<section if="previewSprite == null">
		<exec>
			self.windowSpr.bHeight -= 170;
		</exec>
	</section>

	<exec>
		function onUpdate() {
			if(previewSprite == null) return;
			previewSprite.skew.x = skewXStepper.value;
			previewSprite.skew.y = skewYStepper.value;
			previewSprite.angle = angleStepper.value;
			previewSprite.antialiasing = char.antialiasing;
			var ratio = char.frameWidth / char.frameHeight;
			previewSprite.setGraphicSize(145 * scaleXStepper.value * ratio, 145 * scaleYStepper.value);
			previewSprite.updateHitbox();
			if(flipXCheckbox.checked != char.playerOffsets)
				previewSprite.scale.x *= -1;

			previewSprite.x = 30;
			previewSprite.y = self.winHeight - previewSprite.height - 30;
		}

		function onSave() {
			setEx("highMemory", highMemoryRadio.checked);
			setEx("lowMemory", lowMemoryRadio.checked);

			if (!StringTools.startsWith(char.name, 'NO_DELETE_'))
				char.name = charName.field.text;

			char.x = xStepper.value;
			char.y = yStepper.value;
			char.scrollFactor.set(scrollXStepper.value, scrollYStepper.value);
			char.scale.set(scaleXStepper.value * charScale, scaleYStepper.value * charScale);
			char.cameraOffset.x -= getEx("camX");
			char.cameraOffset.x += camxStepper.value;
			setEx("camX", camxStepper.value);
			char.cameraOffset.y -= getEx("camY");
			char.cameraOffset.y += camyStepper.value;
			setEx("camY", camyStepper.value);
			char.skew.x = skewXStepper.value;
			char.skew.y = skewYStepper.value;
			char.alpha = alphaStepper.value * 0.75;
			setEx("spacingX", spacingXStepper.value);
			setEx("spacingY", spacingYStepper.value);
			if (flipXCheckbox.checked != char.isPlayer) {
				char.isPlayer = flipXCheckbox.checked;
				char.swapLeftRightAnimations();
			}
			char.zoomFactor = zoomFactorStepper.value;
			char.angle = angleStepper.value;
		}
	</exec>
</window>