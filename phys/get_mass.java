package l4d2phys;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.ArrayList;
import java.util.Comparator;

class IntStr {
	float i;
	String s;
}

class CustomComparator implements Comparator<IntStr> {
    @Override
    public int compare(IntStr o1, IntStr o2) {
    	int res1 = -Float.valueOf(o1.i).compareTo(o2.i);
    	if (res1 != 0) return res1;
        return o1.s.compareTo(o2.s);
    }
}

public class Main {

	public static void main(String[] args) throws IOException {
		String folder = "D:\\SteamLibrary\\steamapps\\common\\Left 4 Dead 2\\left4dead2\\ems\\";
		String filename = folder + "phys.txt";
		Path path = Paths.get(filename);
		List<String> lines = Files.readAllLines(path);
		List<IntStr> tosort = new ArrayList<IntStr>();
		for(String line: lines) {
			String model = line.split(" ", 2)[0];
			String physfile = model.substring(1, model.length() - 5) + "phy";
			//System.out.println(physfile + " ");
			Path physfilepath = Paths.get(folder + physfile);
			try {
				byte[] physcontents = Files.readAllBytes(physfilepath);
				String phys_as_string = new String(physcontents, StandardCharsets.US_ASCII);
				//System.out.println(phys_as_string.length());
				//System.out.println(phys_as_string);
				
				Matcher matcher = Pattern.compile("\"mass\" \"(?<value>[0-9\\.]*)\"").matcher(phys_as_string);
				matcher.find();
				float mass = Float.parseFloat(matcher.group("value"));
				if (mass >= 0.5 && Math.abs(Math.round(mass) - mass) < 0.001)
					mass = Math.round(mass);
				//System.out.println(mass);

				matcher = Pattern.compile("\"inertia\" \"(?<value>[0-9\\.]*)\"").matcher(phys_as_string);
				matcher.find();
				float volume = Float.parseFloat(matcher.group("value"));
				//System.out.println(volume);
				
				String values_str = "mass=" + mass + ", volume=" + volume;
				
				String result = line.replace("TODO", values_str);
				
				IntStr intstr = new IntStr();
				intstr.i = mass;
				intstr.s = result;
				tosort.add(intstr);
				//System.out.println(result);
			} catch (IOException e) {
				//System.out.println("NO FILE !!!!!!!!!!!!!!!!!!!!!");
			}
		}
		tosort.sort(new CustomComparator());
		for(IntStr val: tosort) {
			System.out.println(val.s);
		}
	}

}
