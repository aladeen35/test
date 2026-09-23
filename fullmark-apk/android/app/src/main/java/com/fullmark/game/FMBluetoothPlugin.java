package com.fullmark.game;

import android.Manifest;
import android.annotation.SuppressLint;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothServerSocket;
import android.bluetooth.BluetoothSocket;
import android.content.Context;
import android.os.Build;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.PermissionState;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.annotation.Permission;
import com.getcapacitor.annotation.PermissionCallback;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Bluetooth Classic (RFCOMM) link between two phones running Full Mark.
 * The host calls listen(); the player picks the host from its paired devices and calls connect().
 * Messages are newline-delimited JSON strings; each received line is emitted as a "data" event.
 */
@SuppressLint("MissingPermission")
@CapacitorPlugin(
    name = "FMBluetooth",
    permissions = { @Permission(strings = { Manifest.permission.BLUETOOTH_CONNECT }, alias = "bt") }
)
public class FMBluetoothPlugin extends Plugin {

    private static final UUID APP_UUID = UUID.fromString("7d0f1c4e-5b2a-4f7e-9c1d-3a8e6b2f9a41");

    private BluetoothAdapter adapter;
    private BluetoothServerSocket server;
    private BluetoothSocket socket;
    private OutputStream out;
    private final ExecutorService writer = Executors.newSingleThreadExecutor();

    @Override
    public void load() {
        BluetoothManager m = (BluetoothManager) getContext().getSystemService(Context.BLUETOOTH_SERVICE);
        adapter = m != null ? m.getAdapter() : null;
    }

    private boolean needsPermission() {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && getPermissionState("bt") != PermissionState.GRANTED;
    }

    @PluginMethod
    public void ensure(PluginCall call) {
        if (adapter == null) {
            call.reject("هذا الجهاز لا يدعم البلوتوث");
            return;
        }
        if (needsPermission()) {
            requestPermissionForAlias("bt", call, "ensurePermission");
            return;
        }
        JSObject r = new JSObject();
        r.put("enabled", adapter.isEnabled());
        call.resolve(r);
    }

    @PermissionCallback
    private void ensurePermission(PluginCall call) {
        if (needsPermission()) {
            call.reject("يلزم السماح بصلاحية «الأجهزة القريبة» لاستخدام البلوتوث");
            return;
        }
        ensure(call);
    }

    @PluginMethod
    public void listPaired(PluginCall call) {
        if (adapter == null || needsPermission()) {
            call.reject("البلوتوث غير متاح");
            return;
        }
        JSArray list = new JSArray();
        for (BluetoothDevice d : adapter.getBondedDevices()) {
            JSObject o = new JSObject();
            o.put("name", d.getName());
            o.put("address", d.getAddress());
            list.put(o);
        }
        JSObject r = new JSObject();
        r.put("devices", list);
        call.resolve(r);
    }

    @PluginMethod
    public void listen(PluginCall call) {
        if (adapter == null || needsPermission()) {
            call.reject("البلوتوث غير متاح");
            return;
        }
        closeAll();
        try {
            server = adapter.listenUsingRfcommWithServiceRecord("FullMark", APP_UUID);
        } catch (IOException e) {
            call.reject("تعذر بدء الاستماع عبر البلوتوث");
            return;
        }
        final BluetoothServerSocket srv = server;
        new Thread(() -> {
            try {
                BluetoothSocket s = srv.accept();
                try { srv.close(); } catch (IOException ignored) { }
                onConnected(s);
            } catch (IOException ignored) {
                // the server socket was closed (cancelled or disconnected)
            }
        }, "fm-bt-accept").start();
        call.resolve();
    }

    @PluginMethod
    public void connect(PluginCall call) {
        String address = call.getString("address");
        if (adapter == null || needsPermission() || address == null) {
            call.reject("البلوتوث غير متاح");
            return;
        }
        closeAll();
        new Thread(() -> {
            try {
                BluetoothDevice d = adapter.getRemoteDevice(address);
                BluetoothSocket s = d.createRfcommSocketToServiceRecord(APP_UUID);
                s.connect();
                onConnected(s);
                call.resolve();
            } catch (Exception e) {
                call.reject("تعذر الاتصال — تأكد أن المضيف فتح غرفة البلوتوث وينتظر");
            }
        }, "fm-bt-connect").start();
    }

    @PluginMethod
    public void send(PluginCall call) {
        final String data = call.getString("data", "");
        final OutputStream o = out;
        if (o == null) {
            call.reject("غير متصل");
            return;
        }
        writer.execute(() -> {
            try {
                o.write(data.getBytes(StandardCharsets.UTF_8));
                o.flush();
            } catch (IOException e) {
                handleDisconnect();
            }
        });
        call.resolve();
    }

    @PluginMethod
    public void disconnect(PluginCall call) {
        closeAll();
        call.resolve();
    }

    private void onConnected(BluetoothSocket s) throws IOException {
        socket = s;
        out = s.getOutputStream();
        final BufferedReader in = new BufferedReader(new InputStreamReader(s.getInputStream(), StandardCharsets.UTF_8));
        new Thread(() -> {
            try {
                String line;
                while ((line = in.readLine()) != null) {
                    JSObject d = new JSObject();
                    d.put("data", line + "\n");
                    notifyListeners("data", d);
                }
            } catch (IOException ignored) {
                // stream closed
            }
            handleDisconnect();
        }, "fm-bt-read").start();
        JSObject c = new JSObject();
        String name = null;
        try { name = s.getRemoteDevice().getName(); } catch (SecurityException ignored) { }
        c.put("name", name);
        notifyListeners("connected", c);
    }

    private synchronized void handleDisconnect() {
        if (socket == null) return;
        closeAll();
        notifyListeners("disconnected", new JSObject());
    }

    private synchronized void closeAll() {
        try { if (server != null) server.close(); } catch (IOException ignored) { }
        try { if (socket != null) socket.close(); } catch (IOException ignored) { }
        server = null;
        socket = null;
        out = null;
    }

    @Override
    protected void handleOnDestroy() {
        closeAll();
        writer.shutdownNow();
    }
}
