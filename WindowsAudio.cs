using System;
using System.Runtime.InteropServices;
// Windows ABI declarations only; no NirSoft code or binaries are used.
public static class WindowsAudio {
    [ComImport, Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface DeviceEnumerator {
        [PreserveSig] int EnumAudioEndpoints(int flow,uint mask,out IntPtr devices);
        [PreserveSig] int GetDefaultAudioEndpoint(int flow,int role,out Device device);
        [PreserveSig] int GetDevice([MarshalAs(UnmanagedType.LPWStr)] string id,out Device device);
        [PreserveSig] int RegisterEndpointNotificationCallback(IntPtr callback);
        [PreserveSig] int UnregisterEndpointNotificationCallback(IntPtr callback);
    }
    [ComImport, Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface Device {
        [PreserveSig] int Activate(ref Guid iid,uint context,IntPtr parameters,out IntPtr result);
        [PreserveSig] int OpenPropertyStore(uint access,out IntPtr store);
        [PreserveSig] int GetId([MarshalAs(UnmanagedType.LPWStr)] out string id);
        [PreserveSig] int GetState(out uint state);
    }
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    private delegate int EndpointCall(IntPtr self,[MarshalAs(UnmanagedType.LPWStr)] string id,int value);
    private static DeviceEnumerator NewEnumerator() {
        return (DeviceEnumerator)Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")));
    }
    public static string GetDefaultId() {
        var enumerator=NewEnumerator(); Device device=null;
        try {
            int hr=enumerator.GetDefaultAudioEndpoint(0,1,out device);
            if(hr==unchecked((int)0x80070490)) return null;
            Marshal.ThrowExceptionForHR(hr);
            string id; Marshal.ThrowExceptionForHR(device.GetId(out id)); return id;
        } finally { if(device!=null) Marshal.ReleaseComObject(device); Marshal.ReleaseComObject(enumerator); }
    }
    public static uint GetState(string id) {
        var enumerator=NewEnumerator(); Device device=null;
        try {
            Marshal.ThrowExceptionForHR(enumerator.GetDevice(id,out device));
            uint state; Marshal.ThrowExceptionForHR(device.GetState(out state)); return state;
        } finally { if(device!=null) Marshal.ReleaseComObject(device); Marshal.ReleaseComObject(enumerator); }
    }
    private static void CallPolicy(string id,int slot,int value) {
        // IPolicyConfig is an undocumented Windows interface. Keep its ABI isolated here.
        object policy=Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid("870AF99C-171D-4F9E-AF0D-E63DF40C2BC9")));
        IntPtr unknown=IntPtr.Zero, pointer=IntPtr.Zero;
        try {
            unknown=Marshal.GetIUnknownForObject(policy);
            Guid iid=new Guid("F8679F50-850A-41CF-9C72-430F290290C8");
            Marshal.ThrowExceptionForHR(Marshal.QueryInterface(unknown,ref iid,out pointer));
            IntPtr method=Marshal.ReadIntPtr(Marshal.ReadIntPtr(pointer),slot*IntPtr.Size);
            var call=(EndpointCall)Marshal.GetDelegateForFunctionPointer(method,typeof(EndpointCall));
            int hr=call(pointer,id,value);
            if(hr!=0) throw new InvalidOperationException("Windows audio policy failed (0x"+hr.ToString("X8")+").");
        } finally {
            if(pointer!=IntPtr.Zero) Marshal.Release(pointer);
            if(unknown!=IntPtr.Zero) Marshal.Release(unknown);
            Marshal.ReleaseComObject(policy);
        }
    }
    public static void SetDefault(string id) { for(int role=0;role<3;role++) CallPolicy(id,13,role); }
    public static void SetEnabled(string id,bool enabled) { CallPolicy(id,14,enabled?1:0); }
}
