package com.yoshman29.codenameengine;

import android.Manifest;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.net.Uri;
import android.content.Context;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.os.VibratorManager;
import android.provider.Settings;
import android.view.Gravity;
import android.view.View;
import android.view.WindowManager;
import android.widget.RelativeLayout;
import android.widget.TextView;

import java.io.File;
import java.util.LinkedHashSet;
import java.util.Set;

import org.haxe.extension.Extension;

public class MobileActivity extends Extension {
	static final String FOLDER_NAME = "CodenameEngine";
	static final int STORAGE_REQUEST = 3041;
	static TextView bootLabel;

	public static String storagePath() {
		if (mainActivity == null) return "";
		File dir = null;
		if (hasStorageAccess()) dir = writable(new File(Environment.getExternalStorageDirectory(), FOLDER_NAME));
		if (dir == null) {
			File[] media = mainActivity.getExternalMediaDirs();
			if (media != null) {
				for (File candidate : media) {
					dir = writable(candidate);
					if (dir != null) break;
				}
			}
		}
		if (dir == null) dir = writable(mainActivity.getExternalFilesDir(null));
		if (dir == null) dir = mainActivity.getFilesDir();
		return dir == null ? "" : dir.getAbsolutePath();
	}

	public static String extraStoragePaths() {
		if (mainActivity == null) return "";
		LinkedHashSet<String> set = new LinkedHashSet<String>();
		String primary = storagePath();
		File[] media = mainActivity.getExternalMediaDirs();
		if (media != null) {
			for (File candidate : media) addExtra(set, candidate, primary);
		}
		addExtra(set, mainActivity.getObbDir(), primary);
		addExtra(set, mainActivity.getExternalFilesDir(null), primary);
		StringBuilder out = new StringBuilder();
		for (String path : set) {
			if (out.length() > 0) out.append('|');
			out.append(path);
		}
		return out.toString();
	}

	static void addExtra(Set<String> set, File dir, String primary) {
		dir = writable(dir);
		if (dir == null) return;
		String path = dir.getAbsolutePath();
		if (path.equals(primary)) return;
		set.add(path);
	}

	public static boolean hasStorageAccess() {
		if (mainActivity == null) return false;
		if (Build.VERSION.SDK_INT >= 30) return Environment.isExternalStorageManager();
		if (Build.VERSION.SDK_INT >= 23)
			return mainActivity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED;
		return true;
	}

	public static void requestStorageAccess() {
		if (mainActivity == null) return;
		mainActivity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				openStorageSettings();
			}
		});
	}

	static File writable(File dir) {
		if (dir == null) return null;
		if (!dir.exists()) dir.mkdirs();
		return dir.isDirectory() && dir.canWrite() ? dir : null;
	}

	static void openStorageSettings() {
		if (hasStorageAccess()) return;
		if (Build.VERSION.SDK_INT >= 30) {
			try {
				mainActivity.startActivity(new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, Uri.parse("package:" + mainActivity.getPackageName())));
			} catch (Exception e) {
				try {
					mainActivity.startActivity(new Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION));
				} catch (Exception fallback) {
					e.printStackTrace();
					fallback.printStackTrace();
				}
			}
		}
		else if (Build.VERSION.SDK_INT >= 23) {
			mainActivity.requestPermissions(new String[] { Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE }, STORAGE_REQUEST);
		}
	}

	static void askForStorage() {
		if (mainActivity == null || hasStorageAccess()) return;
		final SharedPreferences prefs = mainActivity.getSharedPreferences("codename_mobile", 0);
		if (prefs.getBoolean("askedStorage", false)) return;
		mainActivity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				new AlertDialog.Builder(mainActivity)
					.setTitle("Mods folder")
					.setMessage("Allow file access to keep mods in the " + FOLDER_NAME + " folder of your internal storage.\n\nWithout it, mods go in Android/media/" + mainActivity.getPackageName() + ".")
					.setCancelable(false)
					.setPositiveButton("Allow", new DialogInterface.OnClickListener() {
						@Override
						public void onClick(DialogInterface dialog, int which) {
							prefs.edit().putBoolean("askedStorage", true).apply();
							openStorageSettings();
						}
					})
					.setNegativeButton("Not now", new DialogInterface.OnClickListener() {
						@Override
						public void onClick(DialogInterface dialog, int which) {
							prefs.edit().putBoolean("askedStorage", true).apply();
						}
					})
					.show();
			}
		});
	}

	public static void setBootStatus(final String status) {
		if (mainActivity == null) return;
		mainActivity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				ensureLabel();
				if (status == null || status.length() == 0) {
					bootLabel.setVisibility(View.GONE);
					return;
				}
				bootLabel.setText(status);
				bootLabel.setVisibility(View.VISIBLE);
				bootLabel.bringToFront();
			}
		});
	}

	static void ensureLabel() {
		if (bootLabel != null || !(mainView instanceof android.view.ViewGroup)) return;
		TextView label = new TextView(mainActivity);
		label.setTextColor(Color.BLACK);
		label.setTextSize(22);
		label.setBackgroundColor(Color.YELLOW);
		label.setPadding(24, 16, 24, 16);
		label.setGravity(Gravity.CENTER);
		label.setVisibility(View.GONE);
		RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(
			RelativeLayout.LayoutParams.MATCH_PARENT,
			RelativeLayout.LayoutParams.WRAP_CONTENT
		);
		params.addRule(RelativeLayout.ALIGN_PARENT_TOP);
		((android.view.ViewGroup) mainView).addView(label, params);
		bootLabel = label;
	}

	@SuppressWarnings("deprecation")
	public static void vibrate(int duration) {
		if (mainActivity == null || duration <= 0) return;
		try {
			// split out so api 24 doesnt load VibratorManager
			if (Build.VERSION.SDK_INT >= 31) Vibrator31.vibrate(mainActivity, duration);
			else if (Build.VERSION.SDK_INT >= 26) Vibrator26.vibrate(mainActivity, duration);
			else {
				Vibrator vibrator = (Vibrator) mainActivity.getSystemService(Context.VIBRATOR_SERVICE);
				if (vibrator != null && vibrator.hasVibrator()) vibrator.vibrate(duration);
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	static class Vibrator26 {
		static void vibrate(android.app.Activity activity, int duration) {
			Vibrator vibrator = (Vibrator) activity.getSystemService(Context.VIBRATOR_SERVICE);
			if (vibrator == null || !vibrator.hasVibrator()) return;
			vibrator.vibrate(VibrationEffect.createOneShot(duration, VibrationEffect.DEFAULT_AMPLITUDE));
		}
	}

	static class Vibrator31 {
		static void vibrate(android.app.Activity activity, int duration) {
			VibratorManager manager = (VibratorManager) activity.getSystemService(Context.VIBRATOR_MANAGER_SERVICE);
			if (manager == null) return;
			Vibrator vibrator = manager.getDefaultVibrator();
			if (vibrator == null || !vibrator.hasVibrator()) return;
			vibrator.vibrate(VibrationEffect.createOneShot(duration, VibrationEffect.DEFAULT_AMPLITUDE));
		}
	}

	@Override
	public void onCreate(Bundle savedInstanceState) {
		if (mainActivity == null) return;
		mainActivity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
		askForStorage();
	}

	@Override
	public boolean onBackPressed() {
		return false;
	}
}
