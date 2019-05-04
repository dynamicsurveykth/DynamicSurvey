require 'sinatra'
require 'json'
require 'httparty'
require 'date'

$with_contraints=true           # determine the course/program file to be read


# get configuration data
if $with_contraints
  all_data=JSON.parse(File.read('course-data-EECS-cycle-2c.json'))
else
  all_data=JSON.parse(File.read('course-data-EECS-cycle-2.json'))
end

#all_data=JSON.parse(File.read('TestReferenceFile.json'))

cycle_number=all_data['cycle_number']
puts "cycle_number is #{cycle_number} and it has class #{cycle_number.class}"
puts "school_acronym is #{all_data['school_acronym']}"

session={}

programs_in_the_school_with_titles=all_data['programs_in_the_school_with_titles']

def programs_in_cycle(cycle_number, programs)
  cycle=cycle_number.to_i
  #puts("in programs_in_cycle cycle is #{cycle}")
  relevant_programs={}
  #puts("programs is #{programs}")
  programs.each do |prog_code, prog_value| # you have to iterate this way as programs is a hash
    #puts("prog_code is #{prog_code}")
    #puts("prog_value is #{prog_value}")
    @program_name = prog_code
    #puts("@program_name is #{@program_name}")
    @credits = programs[@program_name]['credits'].to_i
    #puts("@credits is #{@credits}")
    @title_sv = programs[@program_name]['title_sv']

    if (@credits >= 270) and ((cycle == 1) or (cycle == 2))
      #puts("Found Civ. ing. program")
      relevant_programs[prog_code]=prog_value
    elsif (@credits == 180) and (cycle == 1)
      #puts("Found Hög. ing. program")
      relevant_programs[prog_code]=prog_value
    elsif (@credits == 120) and (cycle == 2)
      relevant_programs[prog_code]=prog_value
    elsif (@credits == 30) and (cycle == 0)
      relevant_programs[prog_code]=prog_value
    elsif (@credits == 60) and (cycle == 0) and (@title_sv.include? 'Tekniskt basår')
      relevant_programs[prog_code]=prog_value
    elsif (@credits == 60) and (cycle == 0) and (@title_sv.include? 'Tekniskt basår')
      relevant_programs[prog_code]=prog_value
    elsif (@credits == 60) and (cycle == 2) and (@title_sv.include? 'Magisterprogram')
      relevant_programs[prog_code]=prog_value
    else
      # nothing to do
    end
  end
  return relevant_programs
end

# filter out the programs that are not at the desired cucle
$programs_in_the_school_with_titles=programs_in_cycle(cycle_number, programs_in_the_school_with_titles)
#puts("filtered $programs_in_the_school_with_titles is #{$programs_in_the_school_with_titles}")

dept_codes=all_data['dept_codes']
all_course_examiners=all_data['all_course_examiners']
AF_courses=all_data['AF_courses']
PF_courses=all_data['PF_courses']
relevant_courses_English=all_data['relevant_courses_English']
relevant_courses_Swedish=all_data['relevant_courses_Swedish']


$PF_course_codes_by_program=all_data['PF_course_codes_by_program']
$AF_course_codes_by_program=all_data['AF_course_codes_by_program']


get '/testPrograms' do

  @program_options=''
  program_codes=[]
  @programs=$programs_in_the_school_with_titles.sort #this is a hash
  puts("@programs is #{@programs}")
  # note that each "program" value is of the form ["CDATE", {"owner"=>"EECS", "title_en"=>"Degree Programme in Computer Science and Engineering", "title_sv"=>"Civilingenjörsutbildning i datateknik"}]

  @programs.each do |program|
    #puts("program is #{program}")
    if program.length > 0
      @program_name=program[0]
	  program_codes << @program_name
      puts("@program_name is #{@program_name}")
	  puts("Class of program is #{program.class}") #array
	  puts("Class of program-0 is #{program[0].class}") #string
      @title=$programs_in_the_school_with_titles[@program_name]['title_en']
      @title_s=$programs_in_the_school_with_titles[@program_name]['title_sv']
      puts("title is #{@title}")
      puts("title is #{@title_s}")
      @program_options=@program_options+'<option value="'+@program_name+'">'+@program_name+': '+@title+' | '+@title_s+'</option>'
    end
  end
   
  puts("Class is #{Hash[*@programs.to_a.at(1)].class}")  #hash
  puts("First element of hash is #{Hash[*@programs.to_a.at(0)]}") 
  
  if program_codes[0] == "CDATE"
	puts("Pass 1")
  end
  
  if program_codes[1] == "CELTE"
	puts("Pass 2")
  end
  
  if program_codes[2] == "CINTE"
	puts("Pass 3")
  end
  
  if program_codes[3] == "CMETE"
	puts("Pass 4")
  end
  
  if program_codes[14] == "TMMTM"
	puts("Pass 5")
  end
  
  if program_codes[15] == "TNTEM"
	puts("Pass 6")
  end
  
  if program_codes[16] == "TSCRM"
	puts("Pass 7")
  end
  
  if program_codes[17] == "TSEDM"
	puts("Pass 8")
  end
  
  <<-HTML 
  <html>
	<head ><title ><span lang="en">Which program of study are you in?</span> | <span lang="sv">Vilket studieprogram är du i?</span></title ></head > 
	<body >
          <form action="/gotUsersProgram" method="post">
          <h2>Which program of study are you in?</span> | <span lang="sv">Vilket studieprogram är du i?</span></h2>
          <select if="program_code" name="program_code">
          #{@program_options}
          </select>

           <br><input type='submit' value='Submit' />
          </form>
	</body >
   </html > 
   HTML
end

post "/gotUsersProgram" do
   program_code=params['program_code']
   if !program_code || program_code.empty?
     redirect to("/getUserProgram")
    end
	session['program_code']=program_code
	puts("gotUsersProgram program code is #{program_code}")

   redirect to("/getGeneralData")
end

get '/getGeneralData' do

        @program_code=session['program_code']
        if cycle_number == "1"
          @cycle_number_ordinal='1<sup>st</sup>'
        else
          @cycle_number_ordinal='2<sup>nd</sup>'
        end

        puts("/getGeneralData: @program_code is #{@program_code}")
        planned_start_today=Time.new
        planned_start_min=planned_start_today
        planned_start_max=planned_start_today + (11*30*24*60*60) # 11 months into the future

        #puts("#{$programs_in_the_school_with_titles}")
        #puts("#{$programs_in_the_school_with_titles[@program_code]}")
        #puts("#{$programs_in_the_school_with_titles[@program_code]['title_en']}")

        # all TIVNM students can only take a degree project course with an A-F grade
        if %w(TIVNM ).include? @program_code 
          @graded_or_ungraded_question='<p><span lan="en">All students in ' + @program_code + ' must have A-F grading.</span>/<span lan="sv">Alla elever i ' + @program_code + ' måste ha A-F-gradering.</p>'
        else
          @graded_or_ungraded_question='<h2><span lang="en">Grading scale</span>|<span lang="sv">Betygsskala</span></h2>
        <p><span lang="en">Do you wish an A-F grade, rather than the default P/F (i.e. Pass/Fail) grade for your degree project?</span> |         <span lang="sv">Vill du ha ett betygsatt exjobb (A-F), i stället för ett vanligt med bara P/F (Pass/Fail)?</span></p>
          <span>
              <span>
                  <input type="radio" name="grading_scale"  value="grading_scale_AF"/>&nbsp;<span lan="en">Grade A-F</span> | <span lang="sv">Betygsatt exjobb (A-F)</span><br>
              </span>
              <span>
                  <input type="radio" name="grading_scale"  value="grading_scale_PF" checked="checked" autofocus required="required"/>&nbsp;<span lang="en">Pass/Fail (standard)</span> | <span lang="sv">Godkänd eller underkänd (standard)</span>
              </span>
           </span>'
        end

        
	# now render a simple form the user will submit to "take the quiz"
        <<-HTML
          <html>
          <head><title>Dynamic survey for replacing UT-EXAR form</title></head>
          <body>
          <h1>Application for a #{@cycle_number_ordinal} cycle degree project</h1>
          <form action="/testGeneralData" method="post">
          <p><span lang="en">As a student in the #{$programs_in_the_school_with_titles[@program_code]['title_en']} (#{@program_code}) you need to complete a degree project. This survey collects some data to help admininster your project and to you register for the correct course and be assigned an appropriate examiner.</span> | <span lang="sv">Som student i #{$programs_in_the_school_with_titles[@program_code]['title_sv']} (#{@program_code}) måste du slutföra ett examensarbete. Denna undersökning samlar in några data för att hjälpa till att administrera ditt projekt och att du registrerar dig för rätt kurs och tilldelas en lämplig granskare.</span></p>

          <h2><span lang="en">Full text in DiVA</span> | <span lang="sv">Fulltext i DiVA</span></h2>
          <p><span lang="en">Do you give KTH permission to make the full text of your final report available via DiVA?</span> | <span lang="sv">Ger du KTH tillstånd att publicera hela din slutliga exjobbsrapport elektroniskt i databasen DiVA?</span></p>
          <p><strong><span lang="en">Note that in all cases the report is public and KTH must provide a copy to anyone on request.</span> | <span lang="sv">Observera att din slutliga exjobbsrapport alltid är offentlig, och att KTH alltid måste tillhandahålla en kopia om någon begär det.</span></strong></p>
          <span>
              <span>
                  <input type="radio" name="diva_permission"  value="yes_to_diva" checked="checked" autofocus required="required"/>&nbsp;<span lang="en">I accept publication via DiVA</span> | <span lang="sv">Jag godkänner publicering via DiVA</span><br>
              </span>
              <span>
                  <input type="radio" name="diva_permission"  value="no_to_diva" />&nbsp;<span lang="en">I do not accept publication via DiVA</span> | <span lang="sv">Jag godkänner inte publicering via DiVA</span>
              </span>
           </span>

           <h2><span lang="en">Tentative title</span> | <span lang="sv">Preliminär titel</span></h2>
           <input name='Tentative_title' type='text' width='1000' id='Tentative_title' />

           <h2><span lang="en">Project Description</span> | <span lang="sv">Projekt beskrivning</span></h2>
           <input name='Prelim_description' type='text' width='1000' id='Prelim_description' />

           <h2><span lang="en">At a company, indicate name</span> | <span lang="sv">På företag, ange vilket</span></h2>
           <input name='company' type='text' width='1000' id='company' />

           <h2><span lang="en">Outside Sweden, indicate Country</span> | <span lang="sv">Utomlands, ange land</span></h2>

           <select id="country_code" name="country_code">
           <option value="">--Please choose a contry code | Vänligen välj en landskod--</option>
           <option value="AF">Afghanistan</option>
           <option value="AX">Åland Islands</option>
           <option value="AL">Albania</option>
           <option value="DZ">Algeria</option>
           <option value="AS">American Samoa</option>
           <option value="AD">Andorra</option>
           <option value="AO">Angola</option>
           <option value="AI">Anguilla</option>
           <option value="AQ">Antarctica</option>
           <option value="AG">Antigua and Barbuda</option>
           <option value="AR">Argentina</option>
           <option value="AM">Armenia</option>
           <option value="AW">Aruba</option>
           <option value="AU">Australia</option>
           <option value="AT">Austria</option>
           <option value="AZ">Azerbaijan</option>
           <option value="BS">Bahamas</option>
           <option value="BH">Bahrain</option>
           <option value="BD">Bangladesh</option>
           <option value="BB">Barbados</option>
           <option value="BY">Belarus</option>
           <option value="BE">Belgium</option>
           <option value="BZ">Belize</option>
           <option value="BJ">Benin</option>
           <option value="BM">Bermuda</option>
           <option value="BT">Bhutan</option>
           <option value="BO">Bolivia, Plurinational State of</option>
           <option value="BQ">Bonaire, Sint Eustatius and Saba</option>
           <option value="BA">Bosnia and Herzegovina</option>
           <option value="BW">Botswana</option>
           <option value="BV">Bouvet Island</option>
           <option value="BR">Brazil</option>
           <option value="IO">British Indian Ocean Territory</option>
           <option value="BN">Brunei Darussalam</option>
           <option value="BG">Bulgaria</option>
           <option value="BF">Burkina Faso</option>
           <option value="BI">Burundi</option>
           <option value="KH">Cambodia</option>
           <option value="CM">Cameroon</option>
           <option value="CA">Canada</option>
           <option value="CV">Cape Verde</option>
           <option value="KY">Cayman Islands</option>
           <option value="CF">Central African Republic</option>
           <option value="TD">Chad</option>
           <option value="CL">Chile</option>
           <option value="CN">China</option>
           <option value="CX">Christmas Island</option>
           <option value="CC">Cocos (Keeling) Islands</option>
           <option value="CO">Colombia</option>
           <option value="KM">Comoros</option>
           <option value="CG">Congo</option>
           <option value="CD">Congo, the Democratic Republic of the</option>
           <option value="CK">Cook Islands</option>
           <option value="CR">Costa Rica</option>
           <option value="CI">Côte d'Ivoire</option>
           <option value="HR">Croatia</option>
           <option value="CU">Cuba</option>
           <option value="CW">Curaçao</option>
           <option value="CY">Cyprus</option>
           <option value="CZ">Czech Republic</option>
           <option value="DK">Denmark</option>
           <option value="DJ">Djibouti</option>
           <option value="DM">Dominica</option>
           <option value="DO">Dominican Republic</option>
           <option value="EC">Ecuador</option>
           <option value="EG">Egypt</option>
           <option value="SV">El Salvador</option>
           <option value="GQ">Equatorial Guinea</option>
           <option value="ER">Eritrea</option>
           <option value="EE">Estonia</option>
           <option value="ET">Ethiopia</option>
           <option value="FK">Falkland Islands (Malvinas)</option>
           <option value="FO">Faroe Islands</option>
           <option value="FJ">Fiji</option>
           <option value="FI">Finland</option>
           <option value="FR">France</option>
           <option value="GF">French Guiana</option>
           <option value="PF">French Polynesia</option>
           <option value="TF">French Southern Territories</option>
           <option value="GA">Gabon</option>
           <option value="GM">Gambia</option>
           <option value="GE">Georgia</option>
           <option value="DE">Germany</option>
           <option value="GH">Ghana</option>
           <option value="GI">Gibraltar</option>
           <option value="GR">Greece</option>
           <option value="GL">Greenland</option>
           <option value="GD">Grenada</option>
           <option value="GP">Guadeloupe</option>
           <option value="GU">Guam</option>
           <option value="GT">Guatemala</option>
           <option value="GG">Guernsey</option>
           <option value="GN">Guinea</option>
           <option value="GW">Guinea-Bissau</option>
           <option value="GY">Guyana</option>
           <option value="HT">Haiti</option>
           <option value="HM">Heard Island and McDonald Islands</option>
           <option value="VA">Holy See (Vatican City State)</option>
           <option value="HN">Honduras</option>
           <option value="HK">Hong Kong</option>
           <option value="HU">Hungary</option>
           <option value="IS">Iceland</option>
           <option value="IN">India</option>
           <option value="ID">Indonesia</option>
           <option value="IR">Iran, Islamic Republic of</option>
           <option value="IQ">Iraq</option>
           <option value="IE">Ireland</option>
           <option value="IM">Isle of Man</option>
           <option value="IL">Israel</option>
           <option value="IT">Italy</option>
           <option value="JM">Jamaica</option>
           <option value="JP">Japan</option>
           <option value="JE">Jersey</option>
           <option value="JO">Jordan</option>
           <option value="KZ">Kazakhstan</option>
           <option value="KE">Kenya</option>
           <option value="KI">Kiribati</option>
           <option value="KP">Korea, Democratic People's Republic of</option>
           <option value="KR">Korea, Republic of</option>
           <option value="KW">Kuwait</option>
           <option value="KG">Kyrgyzstan</option>
           <option value="LA">Lao People's Democratic Republic</option>
           <option value="LV">Latvia</option>
           <option value="LB">Lebanon</option>
           <option value="LS">Lesotho</option>
           <option value="LR">Liberia</option>
           <option value="LY">Libya</option>
           <option value="LI">Liechtenstein</option>
           <option value="LT">Lithuania</option>
           <option value="LU">Luxembourg</option>
           <option value="MO">Macao</option>
           <option value="MK">Macedonia, the former Yugoslav Republic of</option>
           <option value="MG">Madagascar</option>
           <option value="MW">Malawi</option>
           <option value="MY">Malaysia</option>
           <option value="MV">Maldives</option>
           <option value="ML">Mali</option>
           <option value="MT">Malta</option>
           <option value="MH">Marshall Islands</option>
           <option value="MQ">Martinique</option>
           <option value="MR">Mauritania</option>
           <option value="MU">Mauritius</option>
           <option value="YT">Mayotte</option>
           <option value="MX">Mexico</option>
           <option value="FM">Micronesia, Federated States of</option>
           <option value="MD">Moldova, Republic of</option>
           <option value="MC">Monaco</option>
           <option value="MN">Mongolia</option>
           <option value="ME">Montenegro</option>
           <option value="MS">Montserrat</option>
           <option value="MA">Morocco</option>
           <option value="MZ">Mozambique</option>
           <option value="MM">Myanmar</option>
           <option value="NA">Namibia</option>
           <option value="NR">Nauru</option>
           <option value="NP">Nepal</option>
           <option value="NL">Netherlands</option>
           <option value="NC">New Caledonia</option>
           <option value="NZ">New Zealand</option>
           <option value="NI">Nicaragua</option>
           <option value="NE">Niger</option>
           <option value="NG">Nigeria</option>
           <option value="NU">Niue</option>
           <option value="NF">Norfolk Island</option>
           <option value="MP">Northern Mariana Islands</option>
           <option value="NO">Norway</option>
           <option value="OM">Oman</option>
           <option value="PK">Pakistan</option>
           <option value="PW">Palau</option>
           <option value="PS">Palestinian Territory, Occupied</option>
           <option value="PA">Panama</option>
           <option value="PG">Papua New Guinea</option>
           <option value="PY">Paraguay</option>
           <option value="PE">Peru</option>
           <option value="PH">Philippines</option>
           <option value="PN">Pitcairn</option>
           <option value="PL">Poland</option>
           <option value="PT">Portugal</option>
           <option value="PR">Puerto Rico</option>
           <option value="QA">Qatar</option>
           <option value="RE">Réunion</option>
           <option value="RO">Romania</option>
           <option value="RU">Russian Federation</option>
           <option value="RW">Rwanda</option>
           <option value="BL">Saint Barthélemy</option>
           <option value="SH">Saint Helena, Ascension and Tristan da Cunha</option>
           <option value="KN">Saint Kitts and Nevis</option>
           <option value="LC">Saint Lucia</option>
           <option value="MF">Saint Martin (French part)</option>
           <option value="PM">Saint Pierre and Miquelon</option>
           <option value="VC">Saint Vincent and the Grenadines</option>
           <option value="WS">Samoa</option>
           <option value="SM">San Marino</option>
           <option value="ST">Sao Tome and Principe</option>
           <option value="SA">Saudi Arabia</option>
           <option value="SN">Senegal</option>
           <option value="RS">Serbia</option>
           <option value="SC">Seychelles</option>
           <option value="SL">Sierra Leone</option>
           <option value="SG">Singapore</option>
           <option value="SX">Sint Maarten (Dutch part)</option>
           <option value="SK">Slovakia</option>
           <option value="SI">Slovenia</option>
           <option value="SB">Solomon Islands</option>
           <option value="SO">Somalia</option>
           <option value="ZA">South Africa</option>
           <option value="GS">South Georgia and the South Sandwich Islands</option>
           <option value="SS">South Sudan</option>
           <option value="ES">Spain</option>
           <option value="LK">Sri Lanka</option>
           <option value="SD">Sudan</option>
           <option value="SR">Suriname</option>
           <option value="SJ">Svalbard and Jan Mayen</option>
           <option value="SZ">Swaziland</option>
           <option value="SE">Sweden</option>
           <option value="CH">Switzerland</option>
           <option value="SY">Syrian Arab Republic</option>
           <option value="TW">Taiwan, Province of China</option>
           <option value="TJ">Tajikistan</option>
           <option value="TZ">Tanzania, United Republic of</option>
           <option value="TH">Thailand</option>
           <option value="TL">Timor-Leste</option>
           <option value="TG">Togo</option>
           <option value="TK">Tokelau</option>
           <option value="TO">Tonga</option>
           <option value="TT">Trinidad and Tobago</option>
           <option value="TN">Tunisia</option>
           <option value="TR">Turkey</option>
           <option value="TM">Turkmenistan</option>
           <option value="TC">Turks and Caicos Islands</option>
           <option value="TV">Tuvalu</option>
           <option value="UG">Uganda</option>
           <option value="UA">Ukraine</option>
           <option value="AE">United Arab Emirates</option>
           <option value="GB">United Kingdom</option>
           <option value="US">United States</option>
           <option value="UM">United States Minor Outlying Islands</option>
           <option value="UY">Uruguay</option>
           <option value="UZ">Uzbekistan</option>
           <option value="VU">Vanuatu</option>
           <option value="VE">Venezuela, Bolivarian Republic of</option>
           <option value="VN">Viet Nam</option>
           <option value="VG">Virgin Islands, British</option>
           <option value="VI">Virgin Islands, U.S.</option>
           <option value="WF">Wallis and Futuna</option>
           <option value="EH">Western Sahara</option>
           <option value="YE">Yemen</option>
           <option value="ZM">Zambia</option>
           <option value="ZW">Zimbabwe</option>
           </select>

           <h2><span lang="en">At another university</span> | <span lang="sv">På annan högskola</span></h2>
           <input name='university' type='text' width='1000' id='university' />

           <h2><span lang="en">Contact</span> | <span lang="sv">Kontaktinformation</span></h2>
           <p><span lang="en">Enter the name and contact details of your contact at a company, other university, etc.</span> | <span lang="sv">Ange namn, e-postadress och annan kontaktinformation f&ouml;r din kontaktperson vid f&ouml;retaget, det andra universitetet, eller motsvarande.</span></p>
           <input name='contact' type='text' width='1000' id='contact' />

           
           <h2><span lang="en">Planned start</span>/<span lang="sv">Startdatum</span></h2>
           <label for="start">Date/Datum:</label>

           <input type="date" id="start" name=planned_start
                  value=#{planned_start_today}
                  min=#{planned_start_min}
                  max=#{planned_start_max}>

            #{@graded_or_ungraded_question}
           <br><input type='submit' value='Submit' />
          </form>
          </body>
          </html>
        HTML
end


post "/testGeneralData" do

  @diva_permission = params['diva_permission']
  
  if @diva_permission == "yes_to_diva"
	puts("diva pass")
  end
  puts "diva_permission is #{@diva_permission}"

  @tentative_title = params['Tentative_title']
  if @tentative_title == "Title"
	puts("title pass")
  end
  puts "Tentative_title is #{@tentative_title}"

  @prelim_description = params['Prelim_description']
  if @prelim_description == "this is a project"
	puts("description pass")
  end
  puts "prelim_description is #{@prelim_description}"

  @company = params['company']
  if @company == "Company AB"
	puts("company pass")
  end
  puts "company is #{@company}"

  @country_code = params['country_code']
  if @country_code == "BA"
	puts("country pass")
  end
  puts("country_code is #{@country_code}")

  @university = params['university']
  if @university == "kth"
	puts("uni pass")
  end
  puts "university is #{@university}"

  @contact = params['contact']
  if @contact == "Jim"
	puts("contact pass")
  end
  puts "contact is #{@contact}"

  @planned_start = params['planned_start']
  if @planned_start == "2019-02-26"
	puts("date pass")
  end
  puts("planned_start is #{@planned_start}")

  if params.has_key?('grading_scale') 
    @grading_scale = params['grading_scale']
  else
    @grading_scale = 'grading_scale_AF'
  end
  if @grading_scale == "grading_scale_PF"
	puts("grading scale pass")
  end
  puts("grading_scale is #{@grading_scale}")

end

get '/testCourses' do

  cycle_code='cycle'+"2"
  programToTest = "CINTE"
  courseToTest_a = "II225X"
  courseToTest_b = "IL228X"
  
  relevant_course_codes=$AF_course_codes_by_program[cycle_code][programToTest]

  #TEST START	
  if relevant_course_codes[0] == courseToTest_a
     puts("pass")
  end
  
  if relevant_course_codes[1] == courseToTest_b
     puts("pass")
  end
  #TEST END
end

get '/testExaminers' do

@potential_examiners=all_course_examiners["DA224X"].sort

selectedCourse = "DA224X"
Examiner_A = "Anders Lansner"
Examiner_B = "Johan Hoffman"

@potential_examiners=all_course_examiners[selectedCourse].sort

puts("Class of potential_examiners: #{@potential_examiners.class}")

	if @potential_examiners[0] == Examiner_A
		puts("pass")
	end
	if @potential_examiners[10] == Examiner_B
		puts("pass")
	end
end

get '/CourseProgramStatistics' do

cycle_code='cycle'+"2"
allCoursesList=[]
minCourses = 1000;
maxCourses = 0


AF_courses.each do |course|
	unless allCoursesList.include?(course)
		allCoursesList << course
	end
end

PF_courses.each do |course|
	unless allCoursesList.include?(course)
		allCoursesList << course
	end
end

allPrograms = programs_in_the_school_with_titles.sort
programs = $programs_in_the_school_with_titles.sort
puts("Total no. of programs is #{allPrograms.length}")
puts("No. of cycle 2 programs is #{programs.length}")

programs.each do |study_program|
	program_code = study_program[0]
	#puts("Program name is #{program_code}")

	available_AF_courses = $AF_course_codes_by_program[cycle_code][program_code]
	
	if not available_AF_courses
		#puts("")
	else
		if available_AF_courses.length > maxCourses
			maxCourses = available_AF_courses.length
		end
		if available_AF_courses.length < minCourses
			minCourses = available_AF_courses.length
		end
	end
	
	available_PF_courses = $PF_course_codes_by_program[cycle_code][program_code]
	
	if not available_PF_courses
		#puts("")
	else
		if available_PF_courses.length > maxCourses
			maxCourses = available_AF_courses.length
		end
		if available_PF_courses.length < minCourses
			minCourses = available_PF_courses.length
		end
	end


end

sorted_courses = allCoursesList.sort
numCourses = sorted_courses.length

puts("Total number of courses is #{numCourses}")
puts("Max number of courses is #{maxCourses}")
puts("Min number of courses is #{minCourses}")

end

get '/getExaminerStatistics' do

examinerList=[]
max_numExaminers = 0
max_examiner_course = ""
min_numExaminers = 1000
min_examiner_course = ""

AF_courses.each do |course|
	potential_examiners = all_course_examiners[course].sort
	if potential_examiners.length > max_numExaminers
		max_numExaminers = potential_examiners.length
		max_examiner_course = course
	end
	if potential_examiners.length < min_numExaminers && potential_examiners.length != 0
		min_numExaminers = potential_examiners.length
		min_examiner_course = course
	end
	#puts("Number of examiners for #{course} is #{potential_examiners.length}")
	potential_examiners.each do |current_examiner|
		unless examinerList.include?(current_examiner)
			examinerList << current_examiner
		end
	end
end

PF_courses.each do |course|
	potential_examiners = all_course_examiners[course].sort
	if potential_examiners.length > max_numExaminers
		max_numExaminers = potential_examiners.length
		max_examiner_course = course
	end
	if potential_examiners.length < min_numExaminers && potential_examiners.length != 0
		min_numExaminers = potential_examiners.length
		min_examiner_course = course
	end
	#puts("Number of examiners for #{course} is #{potential_examiners.length}")
	potential_examiners.each do |current_examiner|
		unless examinerList.include?(current_examiner)
			examinerList << current_examiner
		end
	end
end

sorted_examiners = examinerList.sort
puts(sorted_examiners)
puts("Total number of examiners is #{sorted_examiners.length}")
puts("Maximum number of examiners is #{max_numExaminers}")
puts("The course with the max number of examiners is #{max_examiner_course}")
puts("Minimum number of examiners is #{min_numExaminers}")
puts("The course with the min number of examiners is #{min_examiner_course}")


end
