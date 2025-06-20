package com.example.tracking

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.Button
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class MainActivity : AppCompatActivity() {

    private val LOCATION_PERMISSION_REQUEST_CODE = 100

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val checkPermissionsButton: Button = findViewById(R.id.button_check_permissions)
        checkPermissionsButton.setOnClickListener { checkPermissions() }
    }

    private fun checkPermissions() {
        // Kiểm tra quyền vị trí
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
            != PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION)
            != PackageManager.PERMISSION_GRANTED
        ) {
            // Yêu cầu quyền vị trí
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
                LOCATION_PERMISSION_REQUEST_CODE
            )
        } else {
            // Quyền đã được cấp
            Toast.makeText(this, "Quyền vị trí đã được cấp", Toast.LENGTH_SHORT).show()
            startLocationService()
        }

        // Quyền Internet là quyền bình thường, không cần kiểm tra
        Toast.makeText(this, "Quyền Internet sẵn có", Toast.LENGTH_SHORT).show()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == LOCATION_PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                // Quyền được cấp
                Toast.makeText(this, "Quyền vị trí được cấp", Toast.LENGTH_SHORT).show()
                startLocationService()
            } else {
                // Quyền bị từ chối
                Toast.makeText(this, "Quyền vị trí bị từ chối", Toast.LENGTH_SHORT).show()
                // Tùy chọn: Hướng dẫn người dùng đến cài đặt hoặc vô hiệu hóa tính năng vị trí
            }
        }
    }
    <LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp">

    <Button
    android:id="@+id/button_check_permissions"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:text="Kiểm Tra Quyền" />

    private fun startLocationService() {
        // Thực hiện chức năng dựa trên vị trí tại đây
        // Ví dụ: Khởi động dịch vụ vị trí hoặc lấy vị trí
    }
    private fun isLocationEnabled(): Boolean {
        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }

    private fun startLocationService() {
        if (isLocationEnabled()) {
            // Dịch vụ vị trí đã bật, tiến hành lấy vị trí
            Toast.makeText(this, "Dịch vụ vị trí đã bật", Toast.LENGTH_SHORT).show()
        } else {
            // Hướng dẫn người dùng bật dịch vụ vị trí
            Toast.makeText(this, "Vui lòng bật dịch vụ vị trí", Toast.LENGTH_SHORT).show()
            val intent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
            startActivity(intent)
        }
    }
}