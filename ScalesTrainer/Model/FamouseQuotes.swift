
import Foundation

class FamousQuotes {
    static let shared = FamousQuotes()
    var quotes:[(String,String)] = []
    init() {
        quotes.append(("Do you ask me how good a player you will become? Then tell me how much you practice the scales.","Carl Czerny"))
        quotes.append(("Scales should never be dry. If you are not interested in them, work with them until you do become interested in them.","Artur Rubinstein"))
        quotes.append(("I don't like to practice slowly, never have. But when I do get started at the piano, for the first 10 minutes I play scales, slowly. I've done this all my life. Listen to the sounds you make. The sound of each tone will generate a response in you. It will give you energy.","Van Clipburn"))
        quotes.append(("I consider the practice of scales important not only for the fingers, but also for the discipline of the ear with regard to the feeling of tonality )key), understanding of intervals, and the comprehension of the total compass of the piano.","Josef Hofman"))
        quotes.append(("Give special study to passing the thumb under the hand and passing the hand over the thumb. This makes the practice of scales and arpeggios indispensible.","Jan Paderewski"))
        quotes.append(("You must diligently practice all scales.","Robert Schuman"))
        quotes.append(("I believe this matter of insisting upon a thorough technical knowledge, particularly scale playing, is a very vital one. the mere ability to play a few pieces does not constitue musical proficiency.","Sergei Rachmaninoff"))
        
        quotes.append(("Scales are like brushing your teeth. They are a fundamental part of your routine to maintain the cleanliness and health of your technique.","Martha Argerich"))
        quotes.append(("Practicing scales might seem tedious, but they build the architecture of your playing. The precision and fluidity gained from scales translate directly into your performance.","Alice Sara Ott"))
        quotes.append(("Scales are the skeleton of piano playing. They provide the framework upon which all great music is built.","Yuja Wang"))
        quotes.append(("Scales teach discipline, control, and a deep understanding of the instrument's geography. They are the key to unlocking the piano's full potential.","Hélène Grimaud"))
        quotes.append(("The discipline of scales is the foundation upon which we build our artistry. Without them, our technique would be like a house without a solid base.","Olga Kern"))
        
        quotes.append(("I do not think I could have played anything if I had not studied scales.","Clara Schumann"))
        quotes.append(("The longer I work on the piano, the more I realize the importance of the elementary studies, such as scales.","Artur Schnabel"))
        quotes.append(("Scales are the grammar of music. Without them, you cannot speak the language.","Martha Argerich"))
        quotes.append(("Scales are the skeleton of music. They help you understand the structure and form.","Yuja Wang"))
        quotes.append(("Daily practice of scales is essential for the development of a complete technique.","Carl Czerny"))
        quotes.append(("Practicing scales is like sharpening the blade of a knife; it makes everything else easier and more precise.","Leon Fleisher"))
        quotes.append(("Scales and arpeggios are the cornerstone of a solid piano technique. They build strength and dexterity.","Rosina Lhévinne"))
        quotes.append(("Practicing scales is like daily exercise for an athlete. It keeps the pianist's muscles flexible and strong.","Daniel Barenboim"))

       //quotes.append(("",""))

    }
    
    func getQuote() -> (String, String) {
        let r = Int.random(in: 0...quotes.count-1)
        return quotes[r]
    }
}
