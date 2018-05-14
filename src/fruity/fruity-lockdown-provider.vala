namespace Frida {
	public class FruityLockdownProvider : Object, HostSessionProvider {
		public string id {
			get { return _id; }
		}
		private string _id;

		public string name {
			get { return device_name; }
		}

		public Image? icon {
			get { return device_icon; }
		}

		public HostSessionProviderKind kind {
			get { return HostSessionProviderKind.USB; }
		}

		public string device_name {
			get;
			construct;
		}

		public Image? device_icon {
			get;
			construct;
		}

		public Fruity.DeviceId device_id {
			get;
			construct;
		}

		public Fruity.Udid device_udid {
			get;
			construct;
		}

		public FruityLockdownProvider (string name, Image? icon, Fruity.DeviceId id, Fruity.Udid udid) {
			Object (
				device_name: name,
				device_icon: icon,
				device_id: id,
				device_udid: udid
			);
		}

		construct {
			_id = device_udid.raw_value + ":lockdown";
		}

		public async void close () {
		}

		public async HostSession create (string? location = null) throws Error {
			var session = yield LockdownSession.open (device_id, device_udid);
			yield session.close ();

			throw new Error.NOT_SUPPORTED ("Not yet fully implemented");
		}

		public async void destroy (HostSession host_session) throws Error {
			throw new Error.NOT_SUPPORTED ("Not yet implemented");
		}

		public async AgentSession obtain_agent_session (HostSession host_session, AgentSessionId agent_session_id) throws Error {
			throw new Error.NOT_SUPPORTED ("Not yet implemented");
		}
	}

	private class LockdownSession : Object {
		public Fruity.DeviceId device_id {
			get;
			construct;
		}

		public Fruity.Udid device_udid {
			get;
			construct;
		}

		private Fruity.UsbmuxClient transport = new Fruity.UsbmuxClient ();

		private const uint LOCKDOWN_PORT = 62078;

		private LockdownSession (Fruity.DeviceId device_id, Fruity.Udid device_udid) {
			Object (
				device_id: device_id,
				device_udid: device_udid
			);
		}

		public static async LockdownSession open (Fruity.DeviceId device_id, Fruity.Udid device_udid) throws Error {
			var session = new LockdownSession (device_id, device_udid);
			yield session.establish ();
			return session;
		}

		public async void close () {
			if (transport != null) {
				yield transport.close ();
				transport = null;
			}
		}

		private async void establish () throws Error {
			try {
				yield transport.establish ();

				printerr ("asking for pair record for '%s'!\n", device_udid.raw_value);
				var record = yield transport.read_pair_record (device_udid);
				var host_private_key = record.get_bytes ("HostPrivateKey");
				printerr ("got record! host_private_key.length=%d\n", host_private_key.length);

				yield transport.connect_to_port (device_id, LOCKDOWN_PORT);
			} catch (GLib.Error e) {
				throw new Error.NOT_SUPPORTED (e.message);
			}

			printerr ("CONNECTED!\n");
		}
	}
}