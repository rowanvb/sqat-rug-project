package coverage_api;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

public class CoverageAPI {
	private static final File FILE = new File(".coverage_data.csv");
	
	public static void hit(String _class, String _method) {
		String s = _class + "," + _method + "\n";
		print(s);
	}
	
	public static void hit(String _class, String _method, String _line) {
		String s = _class + "," + _method + "," + _line + "\n";
		print(s);
	}
	
	private static void print(String s) {
		BufferedWriter bw = null;
		FileWriter fw = null;

		try {

			if (!FILE.exists()) {
				FILE.createNewFile();
			}

			fw = new FileWriter(FILE.getAbsoluteFile(), true);
			bw = new BufferedWriter(fw);

			bw.write(s);

		} catch (IOException e) {

			e.printStackTrace();

		} finally {

			try {

				if (bw != null)
					bw.close();

				if (fw != null)
					fw.close();

			} catch (IOException ex) {

				ex.printStackTrace();

			}
		}
	}
}
