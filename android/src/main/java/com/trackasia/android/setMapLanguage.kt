@file:JvmName("TrackasiaMapUtils")

package com.trackasia.android

import com.trackasia.android.maps.TrackasiaMap
import com.trackasia.android.style.expressions.Expression
import com.trackasia.android.style.layers.PropertyFactory
import com.trackasia.android.style.layers.SymbolLayer

fun TrackasiaMap.setMapLanguage(language: String) {
    val layers = this.style?.layers ?: emptyList()

    val languageRegex = Regex("(name:[a-z]+)")

    val symbolLayers = layers.filterIsInstance<SymbolLayer>()

    for (layer in symbolLayers) {
        // continue when there is no current expression
        val expression = layer.textField.expression ?: continue

        // We could skip the current iteration, whenever there is not current language.
        if (!expression.toString().contains(languageRegex)) {
            continue
        }

        val properties =
            "[\"coalesce\", [\"get\",\"name:$language\"],[\"get\",\"name:latin\"],[\"get\",\"name\"]]"

        layer.setProperties(PropertyFactory.textField(Expression.raw(properties)))
    }
}
