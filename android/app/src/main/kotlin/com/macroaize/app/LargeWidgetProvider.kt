package com.macroaize.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import android.app.PendingIntent
import android.content.Intent



class LargeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_large).apply {
                // Open App on Click
                val intent = Intent(context, MainActivity::class.java)
                intent.action = Intent.ACTION_MAIN
                intent.addCategory(Intent.CATEGORY_LAUNCHER)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_log_button_large, pendingIntent)

                // Update Data
                val calories = widgetData.getInt("calories", 0)
                val progress = widgetData.getInt("progress", 0)
                val protein = widgetData.getInt("protein", 0)
                val carbs = widgetData.getInt("carbs", 0)
                val fats = widgetData.getInt("fats", 0)
                val goal = widgetData.getInt("goal", 2000)

                val caloriesLeft = goal - calories
                val displayCalories = if (caloriesLeft < 0) 0 else caloriesLeft

                setTextViewText(R.id.widget_calories_text_large, "$displayCalories")
                setProgressBar(R.id.widget_progress_bar_large, 100, progress, false)

                setTextViewText(R.id.widget_protein_text, "Protein: ${protein}g")
                setProgressBar(R.id.widget_protein_bar, 100, (protein.toFloat() / 150 * 100).toInt(), false) // Example max 150g

                setTextViewText(R.id.widget_carbs_text, "Carbs: ${carbs}g")
                setProgressBar(R.id.widget_carbs_bar, 100, (carbs.toFloat() / 250 * 100).toInt(), false) // Example max 250g

                setTextViewText(R.id.widget_fats_text, "Fats: ${fats}g")
                setProgressBar(R.id.widget_fats_bar, 100, (fats.toFloat() / 80 * 100).toInt(), false) // Example max 80g
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
