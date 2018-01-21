package coverage_api;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

public class CoverageAPI {
	private static final File FILE = new File("sqat_coverage/coverage_data.csv");
	
	public static void hit(String message) {
		print(message);
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
